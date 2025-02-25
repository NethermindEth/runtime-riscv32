// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

#include <unixasmmacros.inc>
#include "AsmOffsets.inc"

#define STACKSIZEOF_ExInfo ((SIZEOF__ExInfo + 15)&(~15))

#define HARDWARE_EXCEPTION 1
#define SOFTWARE_EXCEPTION 0

.global RhpTrapThreads

// -----------------------------------------------------------------------------
// Macro used to create frame of exception throwing helpers (RhpThrowEx, RhpThrowHwEx)
.macro ALLOC_THROW_FRAME exceptionType

    mv  a3, sp

    // Setup a PAL_LIMITED_CONTEXT on the stack {
    .if \exceptionType == HARDWARE_EXCEPTION
        addi  sp, sp, -0x38
        // .cfi_adjust_cfa_offset  0x38
        sw  a3, 0(sp)          // a3 is the SP and a1 is the IP of the fault site
        sw  a1, 4(sp)
    .else
        PROLOG_STACK_ALLOC  0x38
        // .cfi_adjust_cfa_offset  0x38
        sw  a3, 0(sp)          // a3 is the SP and ra is the IP of the fault site
        sw  ra, 4(sp)
    .endif

    // Safely using available registers for floating-point saves
    fsw  fs0, 0x8(sp)
    fsw  fs1, 0xc(sp)
    fsw  fs2, 0x10(sp)
    fsw  fs3, 0x14(sp)
    fsw  fs4, 0x18(sp)
    fsw  fs5, 0x1c(sp)
    fsw  fs6, 0x20(sp)
    fsw  fs7, 0x24(sp)
    fsw  fs8, 0x28(sp)
    fsw  fs9, 0x2c(sp)
    fsw  fs10, 0x30(sp)
    fsw  fs11, 0x34(sp)

    PROLOG_SAVE_REG_PAIR_INDEXED  fp, ra, 0x3с

    sw  zero, 0x8(sp)        // locations reserved for return value, not used for exception handling
    sw  zero, 0xс(sp)
    PROLOG_SAVE_REG_PAIR  s1, s2,  0x10
    PROLOG_SAVE_REG_PAIR  s3, s4,  0x18
    PROLOG_SAVE_REG_PAIR  s5, s6,  0x20
    PROLOG_SAVE_REG_PAIR  s7, s8,  0x28
    PROLOG_SAVE_REG_PAIR  s9, s10, 0x30
    PROLOG_SAVE_REG       s11,     0x38
    // } end PAL_LIMITED_CONTEXT

    PROLOG_STACK_ALLOC STACKSIZEOF_ExInfo
.endm

// -----------------------------------------------------------------------------
// Macro used to create frame of funclet calling helpers (RhpCallXXXXFunclet)
// extraStackSize - extra stack space that the user of the macro can use to
//                   store additional registers
    .macro ALLOC_CALL_FUNCLET_FRAME extraStackSize

        // Using below prolog instead of PROLOG_SAVE_REG_PAIR fp,ra, #-60!
        // is intentional. Above statement would also emit instruction to save
        // sp in fp. If sp is saved in fp in prolog then it is not expected that fp can change in the body
        // of method. However, this method needs to be able to change fp before calling funclet.
        // This is required to access locals in funclet.
        PROLOG_SAVE_REG_PAIR_NO_FP_INDEXED  fp, ra, 0x3с
        PROLOG_SAVE_REG_PAIR  s1, s2,  0x10
        PROLOG_SAVE_REG_PAIR  s3, s4,  0x18
        PROLOG_SAVE_REG_PAIR  s5, s6,  0x20
        PROLOG_SAVE_REG_PAIR  s7, s8,  0x28
        PROLOG_SAVE_REG_PAIR  s9, s10, 0x30
        PROLOG_SAVE_REG       s11,     0x38
        mv  fp, sp
        .cfi_def_cfa_register fp

        .if \extraStackSize != 0
            PROLOG_STACK_ALLOC \extraStackSize
        .endif
    .endm

// Macro used to free frame of funclet calling helpers (RhpCallXXXXFunclet)
// extraStackSize - extra stack space that the user of the macro can use to
//                   store additional registers.
//                   It needs to match the value passed to the corresponding
//                   ALLOC_CALL_FUNCLET_FRAME.
.macro FREE_CALL_FUNCLET_FRAME extraStackSize

    .if \extraStackSize != 0
        EPILOG_STACK_FREE \extraStackSize
    .endif

    EPILOG_RESTORE_REG_PAIR  s1, s2,  0x10
    EPILOG_RESTORE_REG_PAIR  s3, s4,  0x18
    EPILOG_RESTORE_REG_PAIR  s5, s6,  0x20
    EPILOG_RESTORE_REG_PAIR  s7, s8,  0x28
    EPILOG_RESTORE_REG_PAIR  s9, s10, 0x30
    EPILOG_RESTORE_REG       s11,     0x38
    EPILOG_RESTORE_REG_PAIR_INDEXED  fp, ra, 0x3с
.endm

// -----------------------------------------------------------------------------
// Macro used to restore preserved general purpose and FP registers from REGDISPLAY
// regdisplayReg - register pointing to the REGDISPLAY structure
   .macro RESTORE_PRESERVED_REGISTERS regdisplayReg

        // Load general-purpose registers that are defined
        lw  t3, OFFSETOF__REGDISPLAY__pS1(\regdisplayReg)  // Load address of pS1
        lw  s1, 0(t3)                                      // Load pS1 into s1
        lw  t3, OFFSETOF__REGDISPLAY__pS2(\regdisplayReg)  // Load address of pS2
        lw  s2, 0(t3)                                      // Load pS2 into s2
        lw  t3, OFFSETOF__REGDISPLAY__pS3(\regdisplayReg)  // Load address of pS3
        lw  s3, 0(t3)                                      // Load pS3 into s3
        lw  t3, OFFSETOF__REGDISPLAY__pS4(\regdisplayReg)  // Load address of pS4
        lw  s4, 0(t3)                                      // Load pS4 into s4
        lw  t3, OFFSETOF__REGDISPLAY__pS5(\regdisplayReg)  // Load address of pS5
        lw  s5, 0(t3)                                      // Load pS5 into s5
        lw  t3, OFFSETOF__REGDISPLAY__pS6(\regdisplayReg)  // Load address of pS6
        lw  s6, 0(t3)                                      // Load pS6 into s6
        lw  t3, OFFSETOF__REGDISPLAY__pS7(\regdisplayReg)  // Load address of pS7
        lw  s7, 0(t3)                                      // Load pS7 into s7
        lw  t3, OFFSETOF__REGDISPLAY__pS8(\regdisplayReg)  // Load address of pS8
        lw  s8, 0(t3)                                      // Load pS8 into s8
        lw  t3, OFFSETOF__REGDISPLAY__pS9(\regdisplayReg)  // Load address of pS9
        lw  s9, 0(t3)                                      // Load pS9 into s9
        lw  t3, OFFSETOF__REGDISPLAY__pS10(\regdisplayReg) // Load address of pS10
        lw  s10, 0(t3)                                     // Load pS10 into s10
        lw  t3, OFFSETOF__REGDISPLAY__pS11(\regdisplayReg) // Load address of pS11
        lw  s11, 0(t3)                                     // Load pS11 into s11
        lw  t3, OFFSETOF__REGDISPLAY__pFP(\regdisplayReg)  // Load address of pFP
        lw  fp, 0(t3)                                      // Load pFP into fp

        //
        // Load FP preserved registers
        //
        addi t3, \regdisplayReg, OFFSETOF__REGDISPLAY__F   // Base address of floating-point registers
        flw  fs0,  0x20(t3)                                // Load fs0
        flw  fs1,  0x24(t3)                                // Load fs1
        flw  fs2,  0x48(t3)                                // Load fs2
        flw  fs3,  0x4c(t3)                                // Load fs3
        flw  fs4,  0x50(t3)                                // Load fs4
        flw  fs5,  0x54(t3)                                // Load fs5
        flw  fs6,  0x58(t3)                                // Load fs6
        flw  fs7,  0x5c(t3)                                // Load fs7
        flw  fs8,  0x60(t3)                                // Load fs8
        flw  fs9,  0x64(t3)                                // Load fs9
        flw  fs10, 0x68(t3)                                // Load fs10
        flw  fs11, 0x6c(t3)                                // Load fs11

    .endm

// -----------------------------------------------------------------------------
// Macro used to save preserved general purpose and FP registers to REGDISPLAY
// regdisplayReg - register pointing to the REGDISPLAY structure
.macro SAVE_PRESERVED_REGISTERS regdisplayReg

        // Save general purpose registers
        lw  t3, OFFSETOF__REGDISPLAY__pS1(\regdisplayReg)
        sw  s1, 0(t3)
        lw  t3, OFFSETOF__REGDISPLAY__pS2(\regdisplayReg)
        sw  s2, 0(t3)
        lw  t3, OFFSETOF__REGDISPLAY__pS3(\regdisplayReg)
        sw  s3, 0(t3)
        lw  t3, OFFSETOF__REGDISPLAY__pS4(\regdisplayReg)
        sw  s4, 0(t3)
        lw  t3, OFFSETOF__REGDISPLAY__pS5(\regdisplayReg)
        sw  s5, 0(t3)
        lw  t3, OFFSETOF__REGDISPLAY__pS6(\regdisplayReg)
        sw  s6, 0(t3)
        lw  t3, OFFSETOF__REGDISPLAY__pS7(\regdisplayReg)
        sw  s7, 0(t3)
        lw  t3, OFFSETOF__REGDISPLAY__pS8(\regdisplayReg)
        sw  s8, 0(t3)
        lw  t3, OFFSETOF__REGDISPLAY__pS9(\regdisplayReg)
        sw  s9, 0(t3)
        lw  t3, OFFSETOF__REGDISPLAY__pS10(\regdisplayReg)
        sw  s10, 0(t3)
        lw  t3, OFFSETOF__REGDISPLAY__pS11(\regdisplayReg)
        sw  s11, 0(t3)
        lw  t3, OFFSETOF__REGDISPLAY__pFP(\regdisplayReg)
        sw  fp, 0(t3)

        // Save floating-point registers
        addi  t3, \regdisplayReg, OFFSETOF__REGDISPLAY__F
        fsw  fs0,  0x20(t3)
        fsw  fs1,  0x24(t3)
        fsw  fs2,  0x48(t3)
        fsw  fs3,  0x4c(t3)
        fsw  fs4,  0x50(t3)
        fsw  fs5,  0x54(t3)
        fsw  fs6,  0x58(t3)
        fsw  fs7,  0x5c(t3)
        fsw  fs8,  0x60(t3)
        fsw  fs9,  0x64(t3)
        fsw  fs10, 0x68(t3)
        fsw  fs11, 0x6c(t3)

.endm

// -----------------------------------------------------------------------------
// Macro used to thrash preserved general purpose registers in REGDISPLAY
// to make sure nobody uses them
// regdisplayReg - register pointing to the REGDISPLAY structure
.macro TRASH_PRESERVED_REGISTERS_STORAGE regdisplayReg

#if _DEBUG
        // Create a pattern to store
        li  a3, 0xbaaddeed

        // Store the pattern into each register's location
        lw t3, OFFSETOF__REGDISPLAY__pS1(\regdisplayReg)
        sw a3, 0(t3)
        lw t3, OFFSETOF__REGDISPLAY__pS2(\regdisplayReg)
        sw a3, 0(t3)
        lw t3, OFFSETOF__REGDISPLAY__pS3(\regdisplayReg)
        sw a3, 0(t3)
        lw t3, OFFSETOF__REGDISPLAY__pS4(\regdisplayReg)
        sw a3, 0(t3)
        lw t3, OFFSETOF__REGDISPLAY__pS5(\regdisplayReg)
        sw a3, 0(t3)
        lw t3, OFFSETOF__REGDISPLAY__pS6(\regdisplayReg)
        sw a3, 0(t3)
        lw t3, OFFSETOF__REGDISPLAY__pS7(\regdisplayReg)
        sw a3, 0(t3)
        lw t3, OFFSETOF__REGDISPLAY__pS8(\regdisplayReg)
        sw a3, 0(t3)
        lw t3, OFFSETOF__REGDISPLAY__pS9(\regdisplayReg)
        sw a3, 0(t3)
        lw t3, OFFSETOF__REGDISPLAY__pS10(\regdisplayReg)
        sw a3, 0(t3)
        lw t3, OFFSETOF__REGDISPLAY__pS11(\regdisplayReg)
        sw a3, 0(t3)
        lw t3, OFFSETOF__REGDISPLAY__pFP(\regdisplayReg)
        sw a3, 0(t3)
#endif // _DEBUG
.endm

.macro GetThreadA2
    addi  sp, sp, -8
    sw    a0, 0(sp)
    sw    a1, 4(sp)
    call  C_FUNC(RhpGetThread)
    mv    a2, a0
    lw    a0, 0(sp)
    lw    a1, 4(sp)
    addi  sp, sp, 8
.endm

#define rsp_offsetof_ExInfo  0
#define rsp_offsetof_Context STACKSIZEOF_ExInfo

//
// RhpThrowHwEx
//
// INPUT:  a0[31:0]:  exception code of fault
//         a1:  faulting IP
//
// OUTPUT:
//

    NESTED_ENTRY RhpThrowHwEx, _TEXT, NoHandler

        ALLOC_THROW_FRAME HARDWARE_EXCEPTION

        GetThreadA2

        // Compute address for ExInfo*
        addi   a1, sp, rsp_offsetof_ExInfo              // a1 <- ExInfo*
        sw     zero, OFFSETOF__ExInfo__m_exception(a1)    // pExInfo->m_exception = null
        li     a3, 1
        sb     a3, OFFSETOF__ExInfo__m_passNumber(a1)   // pExInfo->m_passNumber = 1
        addi   a3, zero, -1
        sw     a3, OFFSETOF__ExInfo__m_idxCurClause(a1) // pExInfo->m_idxCurClause = MaxTryRegionIdx
        li     a3, 2
        sb     a3, OFFSETOF__ExInfo__m_kind(a1)         // pExInfo->m_kind = ExKind.HardwareFault

        // Link the ExInfo into the thread's ExInfo chain
        lw     a3, OFFSETOF__Thread__m_pExInfoStackHead(a2)
        sw     a3, OFFSETOF__ExInfo__m_pPrevExInfo(a1)       // pExInfo->m_pPrevExInfo = m_pExInfoStackHead
        sw     a1, OFFSETOF__Thread__m_pExInfoStackHead(a2)  // m_pExInfoStackHead = pExInfo

        // Set the exception context field on the ExInfo
        addi   a2, sp, rsp_offsetof_Context                  // a2 <- PAL_LIMITED_CONTEXT*
        sw     a2, OFFSETOF__ExInfo__m_pExContext(a1)        // pExInfo->m_pExContext = pContext

        // a0[31:0]: exception code
        // a1: ExInfo*
        call  C_FUNC(RhThrowHwEx)

    ALTERNATE_ENTRY RhpThrowHwEx2

        // No return
        EMIT_BREAKPOINT

    NESTED_END RhpThrowHwEx, _TEXT

//
// RhpThrowEx
//
// INPUT:  a0:  exception object
//
// OUTPUT:
//

    NESTED_ENTRY RhpThrowEx, _TEXT, NoHandler

        ALLOC_THROW_FRAME SOFTWARE_EXCEPTION

        GetThreadA2

        lw   a1, OFFSETOF__Thread__m_pvHijackedReturnAddress(a2)
        beq  a1, zero, LOCAL_LABEL(NotHijacked)

        lw   a3, OFFSETOF__Thread__m_ppvHijackedReturnAddressLocation(a2)

        // Recompute SP at callsite
        addi  t3, sp, (STACKSIZEOF_ExInfo + SIZEOF__PAL_LIMITED_CONTEXT)
        bltu  a3, t3, LOCAL_LABEL(TailCallWasHijacked) // if (m_ppvHijackedReturnAddressLocation < SP at callsite)

        // Normal case where a valid return address location is hijacked
        sw    a1, 0(a3)
        tail  LOCAL_LABEL(ClearThreadState)

LOCAL_LABEL(TailCallWasHijacked):

        // Abnormal case where the return address location is now invalid because we ended up here via a tail
        // call. In this case, our hijacked return address should be the correct caller of this method.

        // Stick the previous return address in RA as well as in the right spots in our PAL_LIMITED_CONTEXT.
        mv  ra, a1

        // Compute offsets for PAL_LIMITED_CONTEXT
        sw  ra, (rsp_offsetof_Context + OFFSETOF__PAL_LIMITED_CONTEXT__RA)(sp)
        sw  ra, (rsp_offsetof_Context + OFFSETOF__PAL_LIMITED_CONTEXT__IP)(sp)

LOCAL_LABEL(ClearThreadState):

        // Clear the Thread's hijack state
        sw  zero, OFFSETOF__Thread__m_ppvHijackedReturnAddressLocation(a2)
        sw  zero, OFFSETOF__Thread__m_pvHijackedReturnAddress(a2)

LOCAL_LABEL(NotHijacked):

        // Compute the offset for ExInfo
        addi   a1, sp, rsp_offsetof_ExInfo              // a1 <- ExInfo*
        sw     zero, OFFSETOF__ExInfo__m_exception(a1)    // pExInfo->m_exception = null
        li     a3, 1
        sb     a3, OFFSETOF__ExInfo__m_passNumber(a1)   // pExInfo->m_passNumber = 1
        addi   a3, zero, -1
        sw     a3, OFFSETOF__ExInfo__m_idxCurClause(a1) // pExInfo->m_idxCurClause = MaxTryRegionIdx
        li     a3, 1
        sb     a3, OFFSETOF__ExInfo__m_kind(a1)         // pExInfo->m_kind = ExKind.Throw

        // Link the ExInfo into the thread's ExInfo chain
        lw  a3, OFFSETOF__Thread__m_pExInfoStackHead(a2)
        sw  a3, OFFSETOF__ExInfo__m_pPrevExInfo(a1)      // pExInfo->m_pPrevExInfo = m_pExInfoStackHead
        sw  a1, OFFSETOF__Thread__m_pExInfoStackHead(a2) // m_pExInfoStackHead = pExInfo

        // Set the exception context field on the ExInfo
        addi  a2, sp, rsp_offsetof_Context           // a2 <- PAL_LIMITED_CONTEXT*
        sw    a2, OFFSETOF__ExInfo__m_pExContext(a1) // pExInfo->m_pExContext = pContext

        // a0: exception object
        // a1: ExInfo*
        call C_FUNC(RhThrowEx)

    ALTERNATE_ENTRY RhpThrowEx2

        // No return
        EMIT_BREAKPOINT

    NESTED_END RhpThrowEx, _TEXT

//
// void FASTCALL RhpRethrow()
//
// SUMMARY: Similar to RhpThrowEx, except that it passes along the currently active ExInfo
//
// OUTPUT:
//

    NESTED_ENTRY RhpRethrow, _TEXT, NoHandler

        ALLOC_THROW_FRAME SOFTWARE_EXCEPTION

        GetThreadA2

        // a1 <- ExInfo*
        addi  a1, sp, rsp_offsetof_ExInfo
        // pExInfo->m_exception = null
        sw  zero, OFFSETOF__ExInfo__m_exception(a1)
        // init to a deterministic value (ExKind.None)
        sw  zero, OFFSETOF__ExInfo__m_kind(a1)
        // pExInfo->m_passNumber = 1
        li  a3, 1
        sb  a3, OFFSETOF__ExInfo__m_passNumber(a1)
        // pExInfo->m_idxCurClause = MaxTryRegionIdx
        addi   a3, zero, -1
        sw     a3, OFFSETOF__ExInfo__m_idxCurClause(a1)

        // link the ExInfo into the thread's ExInfo chain
        lw  a3, OFFSETOF__Thread__m_pExInfoStackHead(a2)
        // a0 <- current ExInfo
        mv a0, a3
        // pExInfo->m_pPrevExInfo = m_pExInfoStackHead
        sw a3, OFFSETOF__ExInfo__m_pPrevExInfo(a1)
        // m_pExInfoStackHead = pExInfo
        sw a1, OFFSETOF__Thread__m_pExInfoStackHead(a2)

        // set the exception context field on the ExInfo
        // a2 <- PAL_LIMITED_CONTEXT*
        addi  a2, sp, rsp_offsetof_Context
        // pExInfo->m_pExContext = pContext
        sw  a2, OFFSETOF__ExInfo__m_pExContext(a1)

        // a0 contains the currently active ExInfo
        // a1 contains the address of the new ExInfo
        call  C_FUNC(RhRethrow)

    ALTERNATE_ENTRY RhpRethrow2

        // no return
        EMIT_BREAKPOINT
    NESTED_END RhpRethrow, _TEXT

//
// void* FASTCALL RhpCallCatchFunclet(OBJECTREF exceptionObj, void* pHandlerIP, REGDISPLAY* pRegDisplay,
//                                    ExInfo* pExInfo)
//
// INPUT:  a0:  exception object
//         a1:  handler funclet address
//         a2:  REGDISPLAY*
//         a3:  ExInfo*
//
// OUTPUT:
//

    NESTED_ENTRY RhpCallCatchFunclet, _TEXT, NoHandler

        // Allocate space for the call funclet frame
        ALLOC_CALL_FUNCLET_FRAME 0x90

        // Save floating-point registers
        fsw  fs0,  0x00(sp)
        fsw  fs1,  0x04(sp)
        fsw  fs2,  0x08(sp)
        fsw  fs3,  0x0c(sp)
        fsw  fs4,  0x10(sp)
        fsw  fs5,  0x14(sp)
        fsw  fs6,  0x18(sp)
        fsw  fs7,  0x1c(sp)
        fsw  fs8,  0x20(sp)
        fsw  fs9,  0x24(sp)
        fsw  fs10, 0x28(sp)
        fsw  fs11, 0x2c(sp)

        // Save integer registers
        sw  a0, 0x30(sp)    // Save a0 to a3
        sw  a1, 0x34(sp)
        sw  a2, 0x38(sp)
        sw  a3, 0x3c(sp)
        sw  zero, 0x40(sp) // Make space for local "is_not_handling_thread_abort"; last qword will store the thread obj

#define rsp_offset_is_not_handling_thread_abort 0x40
#define rsp_offset_a0 0x30
#define rsp_offset_a1 0x34
#define rsp_offset_a2 0x38
#define rsp_offset_a3 0x3c
#define rsp_CatchFunclet_offset_thread 0x44

        // Clear the DoNotTriggerGc flag, trashes a4-a6
        call  C_FUNC(RhpGetThread)  // Call the RhpGetThread function
        sw  a0, rsp_CatchFunclet_offset_thread(sp)
        mv  a5, a0
        lw  a0, rsp_offset_a0(sp)
        lw  a1, rsp_offset_a1(sp)
        lw  a2, rsp_offset_a2(sp)
        lw  a3, rsp_offset_a3(sp)

        lw  a4, OFFSETOF__Thread__m_threadAbortException(a5)
        sub a4, a4, a0
        sw  a4, rsp_offset_is_not_handling_thread_abort(sp) // Non-zero if the exception is not ThreadAbortException

        addi  t3, a5, OFFSETOF__Thread__m_ThreadStateFlags

        addi   a6, zero, -17  // Mask value (0xFFFFFFEF)
        amoand.w  a4, a6, (t3)

        // Set preserved regs to the values expected by the funclet
        RESTORE_PRESERVED_REGISTERS a2

        // Trash the values at the old homes to make sure nobody uses them
        TRASH_PRESERVED_REGISTERS_STORAGE a2

        // Call the funclet
        // a0 still contains the exception object
        jalr  a1 // Jump to the handler funclet

    ALTERNATE_ENTRY RhpCallCatchFunclet2

        // a0 contains resume IP

        lw  a2, rsp_offset_a2(sp) // a2 <- REGDISPLAY*

#ifdef _DEBUG
        // Call into some C++ code to validate the pop of the ExInfo. We only do this in debug because we
        // have to spill all the preserved registers and then refill them after the call.

        sw  a0, rsp_offset_a0(sp)

        SAVE_PRESERVED_REGISTERS a2

        lw  a0, rsp_CatchFunclet_offset_thread(sp) // a0 <- Thread*
        lw  a1, rsp_offset_a3(sp)                  // a1 <- current ExInfo*
        lw  a2, OFFSETOF__REGDISPLAY__SP(a2)       // a2 <- resume SP value
        call  C_FUNC(RhpValidateExInfoPop)

        lw  a2, rsp_offset_a2(sp)                  // a2 <- REGDISPLAY*

        RESTORE_PRESERVED_REGISTERS a2

        lw  a0, rsp_offset_a0(sp)                  // Reload resume IP
#endif

        lw  a1, rsp_CatchFunclet_offset_thread(sp)

        // We must unhijack the thread at this point because the section of stack where the hijack is applied
        // may go dead. If it does, then the next time we try to unhijack the thread, it will corrupt the stack.
        INLINE_THREAD_UNHIJACK a1, a3, t3  // Thread in a1, trashes a3 and t3

        lw  a3, rsp_offset_a3(sp)                         // a3 <- current ExInfo*
        lw  a2, OFFSETOF__REGDISPLAY__SP(a2)              // a2 <- resume SP value

LOCAL_LABEL(PopExInfoLoop):
        lw   a3, OFFSETOF__ExInfo__m_pPrevExInfo(a3)      // a3 <- next ExInfo
        beq  a3, zero, LOCAL_LABEL(DonePopping)           // if (pExInfo == null) { we're done }
        blt  a3, a2, LOCAL_LABEL(PopExInfoLoop)           // if (pExInfo < resume SP} { keep going }

LOCAL_LABEL(DonePopping):
        sw  a3, OFFSETOF__Thread__m_pExInfoStackHead(a1)  // Store the new head on the Thread

        PREPARE_EXTERNAL_VAR_INDIRECT_W RhpTrapThreads, a3

        // Use `andi` with the immediate value 0
        andi  a6, a3, (1 << TrapThreadsFlags_AbortInProgress_Bit)  // Apply the mask directly
        beq   a6, zero, LOCAL_LABEL(NoAbort)

        lw   a3, rsp_offset_is_not_handling_thread_abort(sp)
        bne  a3, zero, LOCAL_LABEL(NoAbort)

        // It was the ThreadAbortException, so rethrow it
        // Reset SP
        mv  a1, a0  // a1 <- continuation address as exception PC
        li  a0, STATUS_REDHAWK_THREAD_ABORT
        mv  sp, a2
        tail  C_FUNC(RhpThrowHwEx)

LOCAL_LABEL(NoAbort):
        // Reset SP and jump to continuation address
        mv  sp, a2
        jalr  zero, 0(a0)  // Jump to the continuation address

#undef rsp_offset_is_not_handling_thread_abort
#undef rsp_offset_a0
#undef rsp_offset_a1
#undef rsp_offset_a2
#undef rsp_offset_a3
#undef rsp_CatchFunclet_offset_thread

    NESTED_END RhpCallCatchFunclet, _TEXT

//
// void FASTCALL RhpCallFinallyFunclet(void* pHandlerIP, REGDISPLAY* pRegDisplay)
//
// INPUT:  a0:  handler funclet address
//         a1:  REGDISPLAY*
//
// OUTPUT:
//

    NESTED_ENTRY RhpCallFinallyFunclet, _TEXT, NoHandler

        // Allocate space for the call funclet frame
        ALLOC_CALL_FUNCLET_FRAME 0x40

        // Save floating-point registers
        fsw  fs0,  0x00(sp)
        fsw  fs1,  0x04(sp)
        fsw  fs2,  0x08(sp)
        fsw  fs3,  0x0c(sp)
        fsw  fs4,  0x10(sp)
        fsw  fs5,  0x14(sp)
        fsw  fs6,  0x18(sp)
        fsw  fs7,  0x1c(sp)
        fsw  fs8,  0x20(sp)
        fsw  fs9,  0x24(sp)
        fsw  fs10, 0x28(sp)
        fsw  fs11, 0x2c(sp)

        // Save integer registers
        sw a0, 0x30(sp)  // Save a0 to 0x60
        sw a1, 0x34(sp)  // Save a1 to 0x68

#define rsp_offset_a1 0x34
#define rsp_FinallyFunclet_offset_thread 0x38

        // Clear the DoNotTriggerGc flag
        call  C_FUNC(RhpGetThread)
        sw  a0, rsp_FinallyFunclet_offset_thread(sp)
        mv  a2, a0
        lw  a0, 0x30(sp)
        lw  a1, 0x34(sp)

        // Set the DoNotTriggerGc flag
        addi  t3, a2, OFFSETOF__Thread__m_ThreadStateFlags
        addi  a3, zero, -17  // Mask value (0xFFFFFFEF)
        amoand.w  a4, a3, (t3)

        // Restore preserved registers
        RESTORE_PRESERVED_REGISTERS a1

        // Trash the values at the old homes to make sure nobody uses them
        TRASH_PRESERVED_REGISTERS_STORAGE a1

        // Call the funclet
        jalr  a0  // Jump to the funclet

    ALTERNATE_ENTRY RhpCallFinallyFunclet2

        lw  a1, rsp_offset_a1(sp)  // Reload REGDISPLAY pointer

        // Save new values of preserved registers into REGDISPLAY
        SAVE_PRESERVED_REGISTERS a1

        // Restore the DoNotTriggerGc flag
        lw  a2, rsp_FinallyFunclet_offset_thread(sp)

        addi  t3, a2, OFFSETOF__Thread__m_ThreadStateFlags
        addi  a3, zero, 16  // Mask value (0x10)
        amoor.w  a1, a3, (t3)

        // Restore floating-point registers
        flw  fs0,  0x00(sp)
        flw  fs1,  0x04(sp)
        flw  fs2,  0x08(sp)
        flw  fs3,  0x0c(sp)
        flw  fs4,  0x10(sp)
        flw  fs5,  0x14(sp)
        flw  fs6,  0x18(sp)
        flw  fs7,  0x1c(sp)
        flw  fs8,  0x20(sp)
        flw  fs9,  0x24(sp)
        flw  fs10, 0x28(sp)
        flw  fs11, 0x2c(sp)

        // Free call funclet frame
        FREE_CALL_FUNCLET_FRAME 0x40
        
        // Return
        EPILOG_RETURN

#undef rsp_offset_a1
#undef rsp_FinallyFunclet_offset_thread

    NESTED_END RhpCallFinallyFunclet, _TEXT

//
// void* FASTCALL RhpCallFilterFunclet(OBJECTREF exceptionObj, void* pFilterIP, REGDISPLAY* pRegDisplay)
//
// INPUT:  a0:  exception object
//         a1:  filter funclet address
//         a2:  REGDISPLAY*
//
// OUTPUT:
//

    NESTED_ENTRY RhpCallFilterFunclet, _TEXT, NoHandler
        ALLOC_CALL_FUNCLET_FRAME 0x30
        fsw  fs0,  0x00(sp)
        fsw  fs1,  0x04(sp)
        fsw  fs2,  0x08(sp)
        fsw  fs3,  0x0c(sp)
        fsw  fs4,  0x10(sp)
        fsw  fs5,  0x14(sp)
        fsw  fs6,  0x18(sp)
        fsw  fs7,  0x1c(sp)
        fsw  fs8,  0x20(sp)
        fsw  fs9,  0x24(sp)
        fsw  fs10, 0x28(sp)
        fsw  fs11, 0x2c(sp)

        lw  t3, OFFSETOF__REGDISPLAY__pFP(a2)
        lw  fp, 0(t3)

        //
        // call the funclet
        //
        // a0 still contains the exception object
        jalr  a1

    ALTERNATE_ENTRY RhpCallFilterFunclet2

        flw  fs0,  0x00(sp)
        flw  fs1,  0x04(sp)
        flw  fs2,  0x08(sp)
        flw  fs3,  0x0c(sp)
        flw  fs4,  0x10(sp)
        flw  fs5,  0x14(sp)
        flw  fs6,  0x18(sp)
        flw  fs7,  0x1c(sp)
        flw  fs8,  0x20(sp)
        flw  fs9,  0x24(sp)
        flw  fs10, 0x28(sp)
        flw  fs11, 0x2c(sp)

        FREE_CALL_FUNCLET_FRAME 0x30
        EPILOG_RETURN

    NESTED_END RhpCallFilterFunclet, Text

#ifdef FEATURE_OBJCMARSHAL

//
// void* FASTCALL RhpCallPropagateExceptionCallback(void* pCallbackContext, void* pCallback, REGDISPLAY* pRegDisplay,
//                                    ExInfo* pExInfo, PInvokeTransitionFrame* pPreviousTransitionFrame)
//
// INPUT:  a0:  callback context
//         a1:  callback
//         a2:  REGDISPLAY*
//         a3:  ExInfo*
//         a4:  pPreviousTransitionFrame
//
// OUTPUT:
//

    NESTED_ENTRY RhpCallPropagateExceptionCallback, _TEXT, NoHandler

#define rsp_offset_a0 0x10
#define rsp_offset_a1 0x14
#define rsp_offset_a2 0x18
#define rsp_offset_a3 0x1c
#define rsp_offset_a4 0x20
#define rsp_CallPropagationCallback_offset_thread 0x24

        // Using the NO_FP macro so that the debugger unwinds using SP.
        // This makes backtraces work even after using RESTORE_PRESERVED_REGISTERS.
        PROLOG_SAVE_REG_PAIR_NO_FP_INDEXED fp, ra, 0x28
        mv    fp, sp
        sw    a0, rsp_offset_a0(sp)  // a0 to a4 are stored to restore them anytime
        sw    a1, rsp_offset_a1(sp)
        sw    a2, rsp_offset_a2(sp)
        sw    a3, rsp_offset_a3(sp)
        sw    a4, rsp_offset_a4(sp)
        sw    zero, rsp_CallPropagationCallback_offset_thread(sp) // zero makes space to store the thread obj

        // clear the DoNotTriggerGc flag, trashes a4-a6
        call  C_FUNC(RhpGetThread)
        sw    a0, rsp_CallPropagationCallback_offset_thread(sp)
        mv    a5, a0
        lw    a0, rsp_offset_a0(sp)
        lw    a1, rsp_offset_a1(sp)
        lw    a2, rsp_offset_a2(sp)
        lw    a3, rsp_offset_a3(sp)

        addi  t3, a5, OFFSETOF__Thread__m_ThreadStateFlags

        addi  a6, zero, -17  // Mask value (0xFFFFFFEF)
        amoand.w  a4, t3, a6

        // set preserved regs to the values expected by the funclet
        RESTORE_PRESERVED_REGISTERS a2
        // trash the values at the old homes to make sure nobody uses them
        TRASH_PRESERVED_REGISTERS_STORAGE a2

#ifdef _DEBUG
        // Call into some C++ code to validate the pop of the ExInfo.  We only do this in debug because we
        // have to spill all the preserved registers and then refill them after the call.

        SAVE_PRESERVED_REGISTERS a2

        lw    a0, rsp_CallPropagationCallback_offset_thread(sp)  // a0 <- Thread*
        lw    a1, rsp_offset_a3(sp)                              // a1 <- current ExInfo*
        lw    a2, OFFSETOF__REGDISPLAY__SP(a2)                   // a2 <- resume SP value
        call  C_FUNC(RhpValidateExInfoPop)

        lw    a2, rsp_offset_a2(sp)                              // a2 <- REGDISPLAY*

        RESTORE_PRESERVED_REGISTERS a2
#endif

        lw    a1, rsp_CallPropagationCallback_offset_thread(sp)

        // We must unhijack the thread at this point because the section of stack where the hijack is applied
        // may go dead.  If it does, then the next time we try to unhijack the thread, it will corrupt the stack.
        INLINE_THREAD_UNHIJACK a1, a3, t3              // Thread in a1, trashes a3 and t3

        lw    a3, rsp_offset_a3(sp)                    // a3 <- current ExInfo*
        lw    a2, OFFSETOF__REGDISPLAY__SP(a2)         // a2 <- resume SP value

LOCAL_LABEL(Propagate_PopExInfoLoop):
        lw    a3, OFFSETOF__ExInfo__m_pPrevExInfo(a3)       // a3 <- next ExInfo
        beqz  a3, LOCAL_LABEL(Propagate_DonePopping)        // if (pExInfo == null) { we're done }
        blt   a3, a2, LOCAL_LABEL(Propagate_PopExInfoLoop)  // if (pExInfo < resume SP) { keep going }

LOCAL_LABEL(Propagate_DonePopping):
        sw    a3, OFFSETOF__Thread__m_pExInfoStackHead(a1)  // store the new head on the Thread

        // restore preemptive mode
        lw    a4, rsp_offset_a4(sp)                         // pPreviousTransitionFrame
        sw    a4, OFFSETOF__Thread__m_pTransitionFrame(a1)

        // reset SP and RA and jump to continuation address
        lw    a0, rsp_offset_a0(sp)                    // callback context
        lw    a1, rsp_offset_a1(sp)                    // callback
        lw    a2, rsp_offset_a2(sp)                    // REGDISPLAY*
        lw    a3, OFFSETOF__REGDISPLAY__pRA(a2)        // a3 <- &resume RA value
        lw    ra, 0(a3)
        lw    a3, OFFSETOF__REGDISPLAY__SP(a2)         // a3 <- resume SP value
        mv    sp, a3
        jalr  zero, 0(a1)

#undef rsp_offset_a0
#undef rsp_offset_a1
#undef rsp_offset_a2
#undef rsp_offset_a3
#undef rsp_CallPropagationCallback_offset_thread

    NESTED_END RhpCallPropagateExceptionCallback, _TEXT

#endif // FEATURE_OBJCMARSHAL
