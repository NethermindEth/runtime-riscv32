// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

#include <unixasmmacros.inc>
#include "AsmOffsets.inc"

#define PROBE_FRAME_SIZE 0x58  // 4 * 4  for fixed part of PInvokeTransitionFrame (fp, ra, m_pThread, m_Flags) +
                               // 11 * 4 for callee saved registers +
                               // 1 * 4  for caller SP +
                               // 2 * 4  for int returns +
                               // 4 * 4  for FP returns

// Define the prolog for setting up the PInvokeTransitionFrame
.macro PUSH_PROBE_FRAME threadReg, trashReg, BITMASK

    # Define the method prologue, allocating enough stack space for the PInvokeTransitionFrame and saving
    # incoming register values into it.

    # First create PInvokeTransitionFrame
    PROLOG_SAVE_REG_PAIR_INDEXED  fp, ra, PROBE_FRAME_SIZE  # Push down stack pointer and store FP (s10) and RA (ra)

    # Slot at sp+0x8 is reserved for Thread *
    # Slot at sp+0xc is reserved for bitmask of saved registers

    # Save callee-saved registers
    PROLOG_SAVE_REG_PAIR  s1, s2,  0x10
    PROLOG_SAVE_REG_PAIR  s3, s4,  0x18
    PROLOG_SAVE_REG_PAIR  s5, s6,  0x20
    PROLOG_SAVE_REG_PAIR  s7, s8,  0x28
    PROLOG_SAVE_REG_PAIR  s9, s10, 0x30
    PROLOG_SAVE_REG       s11,     0x38

    # Slot at sp+0x3c is reserved for caller sp

    # Save the integer return registers
    sw  a0, 0x40(sp)
    sw  a1, 0x44(sp)

    # Save the FP return registers
    fsw  fa0, 0x48(sp)
    fsw  fa1, 0x4c(sp)
    fsw  fa2, 0x50(sp)
    fsw  fa3, 0x54(sp)

    # Perform the rest of the PInvokeTransitionFrame initialization.
    sw  \threadReg, OFFSETOF__PInvokeTransitionFrame__m_pThread(sp)        # Thread * (unused by stackwalker)
    sw  \BITMASK, (OFFSETOF__PInvokeTransitionFrame__m_pThread + 4)(sp)    # Save the register bitmask passed in by caller

    addi  \trashReg, sp, PROBE_FRAME_SIZE                                  # Recover value of caller's SP
    sw  \trashReg, 0x3c(sp)                                                # Save caller's SP

    # Link the frame into the Thread
    mv  \trashReg, sp
    sw  \trashReg, OFFSETOF__Thread__m_pDeferredTransitionFrame(\threadReg)

.endm

// Define the prolog for removing the PInvokeTransitionFrame
.macro POP_PROBE_FRAME

    // Restore the integer return registers
    lw  a0, 0x40(sp)
    lw  a1, 0x44(sp)

    // Restore the FP return registers
    flw  fa0, 0x48(sp)
    flw  fa1, 0x4c(sp)
    flw  fa2, 0x50(sp)
    flw  fa3, 0x54(sp)

    // Restore callee saved registers
    EPILOG_RESTORE_REG_PAIR s1, s2,  0x10
    EPILOG_RESTORE_REG_PAIR s3, s4,  0x18
    EPILOG_RESTORE_REG_PAIR s5, s6,  0x20
    EPILOG_RESTORE_REG_PAIR s7, s8,  0x28
    EPILOG_RESTORE_REG_PAIR s9, s10, 0x30
    EPILOG_RESTORE_REG      s11,     0x38

    // Restore the frame pointer and return address
    EPILOG_RESTORE_REG_PAIR_INDEXED  fp, ra, PROBE_FRAME_SIZE
.endm

// Fix up the hijacked callstack
.macro FixupHijackedCallstack

    // a2 <- GetThread()
#ifdef FEATURE_EMULATED_TLS
    GETTHREAD_ETLS_2
#else
    INLINE_GETTHREAD a2
#endif

    // Fix the stack by restoring the original return address
    lw  ra, OFFSETOF__Thread__m_pvHijackedReturnAddress(a2)

    // Clear hijack state
    sw  zero, OFFSETOF__Thread__m_ppvHijackedReturnAddressLocation(a2)
    sw  zero, OFFSETOF__Thread__m_pvHijackedReturnAddress(a2)
.endm

//
// GC Probe Hijack target
//
NESTED_ENTRY RhpGcProbeHijack, _TEXT, NoHandler
    FixupHijackedCallstack

    PREPARE_EXTERNAL_VAR_INDIRECT_W RhpTrapThreads, a3
    andi  t3, a3, 1 << TrapThreadsFlags_TrapThreads_Bit
    bnez  t3, LOCAL_LABEL(WaitForGC)
    jr  ra

LOCAL_LABEL(WaitForGC):
    li  t6, (DEFAULT_FRAME_SAVE_FLAGS + PTFF_SAVE_A0 + PTFF_SAVE_A1 + PTFF_THREAD_HIJACK_HI)
    or  t3, t3, t6
    tail  C_FUNC(RhpWaitForGC)
NESTED_END RhpGcProbeHijack

.global C_FUNC(RhpThrowHwEx)

// Wait for GC function
NESTED_ENTRY RhpWaitForGC, _TEXT, NoHandler
    PUSH_PROBE_FRAME a2, a3, t3

    lw  a0, OFFSETOF__Thread__m_pDeferredTransitionFrame(a2)
    call  C_FUNC(RhpWaitForGC2)

    lw  a2, OFFSETOF__PInvokeTransitionFrame__m_Flags(sp)

    # Load PTFF_THREAD_ABORT_BIT into a register, using t2 if needed
    slli  t2, a2, (31-PTFF_THREAD_ABORT_BIT)
    srli  t2, t2, 31
    bnez  t2, LOCAL_LABEL(ThrowThreadAbort)

    .cfi_remember_state
    POP_PROBE_FRAME
    EPILOG_RETURN

    .cfi_restore_state
LOCAL_LABEL(ThrowThreadAbort):
    POP_PROBE_FRAME
    li  a0, STATUS_REDHAWK_THREAD_ABORT
    mv  a1, ra      # Set return address as exception PC
    call  C_FUNC(RhpThrowHwEx)
NESTED_END RhpWaitForGC

.global C_FUNC(RhpGcPoll2)

// GC Poll function
LEAF_ENTRY RhpGcPoll
    PREPARE_EXTERNAL_VAR_INDIRECT_W RhpTrapThreads, a0
    bne   a0, zero, C_FUNC(RhpGcPollRare)
    jr  ra
LEAF_END RhpGcPoll

// Rare GC Poll function
NESTED_ENTRY RhpGcPollRare, _TEXT, NoHandler
    PUSH_COOP_PINVOKE_FRAME a0
    call  RhpGcPoll2
    POP_COOP_PINVOKE_FRAME
    jr  ra
NESTED_END RhpGcPollRare

#ifdef FEATURE_GC_STRESS

// GC Stress Hijack targets
LEAF_ENTRY RhpGcStressHijack, _TEXT
    // Not Yet Implemented (NYI)
    EMIT_BREAKPOINT
LEAF_END RhpGcStressHijack, _TEXT

#endif  // FEATURE_GC_STRESS
