// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.
//
// Implementation of _CONTEXT_CaptureContext for the RISCV32 platform.
// This function is processor dependent.  It is used by exception handling,
// and is always apply to the current thread.
//

#include "unixasmmacros.inc"
#include "asmconstants.h"

// Incoming:
//  a0: Context*
//  a1: Exception*
//
LEAF_ENTRY RtlRestoreContext, _TEXT
#ifdef HAS_ASAN
#pragma error("TODO-RISCV32-CQ: unimplemented on RISCV32 yet")
#endif

    mv  t4, a0
    lw  t1, CONTEXT_ContextFlags(t4)
    andi t1, t1, 0x1 << CONTEXT_FLOATING_POINT_BIT
    beqz t1, LOCAL_LABEL(No_Restore_CONTEXT_FLOATING_POINT)

    //64-bits FPR.
    addi t0, t4, CONTEXT_FPU_OFFSET

    flw  f0, (CONTEXT_F0)(t0)
    flw  f1, (CONTEXT_F1)(t0)
    flw  f2, (CONTEXT_F2)(t0)
    flw  f3, (CONTEXT_F3)(t0)
    flw  f4, (CONTEXT_F4)(t0)
    flw  f5, (CONTEXT_F5)(t0)
    flw  f6, (CONTEXT_F6)(t0)
    flw  f7, (CONTEXT_F7)(t0)
    flw  f8, (CONTEXT_F8)(t0)
    flw  f9, (CONTEXT_F9)(t0)
    flw  f10, (CONTEXT_F10)(t0)
    flw  f11, (CONTEXT_F11)(t0)
    flw  f12, (CONTEXT_F12)(t0)
    flw  f13, (CONTEXT_F13)(t0)
    flw  f14, (CONTEXT_F14)(t0)
    flw  f15, (CONTEXT_F15)(t0)
    flw  f16, (CONTEXT_F16)(t0)
    flw  f17, (CONTEXT_F17)(t0)
    flw  f18, (CONTEXT_F18)(t0)
    flw  f19, (CONTEXT_F19)(t0)
    flw  f20, (CONTEXT_F20)(t0)
    flw  f21, (CONTEXT_F21)(t0)
    flw  f22, (CONTEXT_F22)(t0)
    flw  f23, (CONTEXT_F23)(t0)
    flw  f24, (CONTEXT_F24)(t0)
    flw  f25, (CONTEXT_F25)(t0)
    flw  f26, (CONTEXT_F26)(t0)
    flw  f27, (CONTEXT_F27)(t0)
    flw  f28, (CONTEXT_F28)(t0)
    flw  f29, (CONTEXT_F29)(t0)
    flw  f30, (CONTEXT_F30)(t0)
    flw  f31, (CONTEXT_F31)(t0)

    lw t1, (CONTEXT_FLOAT_CONTROL_OFFSET)(t0)
    fscsr x0, t1

LOCAL_LABEL(No_Restore_CONTEXT_FLOATING_POINT):

    lw  t1, CONTEXT_ContextFlags(t4)
    andi t1, t1, 0x1 << CONTEXT_INTEGER_BIT
    beqz t1, LOCAL_LABEL(No_Restore_CONTEXT_INTEGER)

    lw  tp, (CONTEXT_Tp)(a0)
    lw  gp, (CONTEXT_Gp)(a0)
    lw  a1, (CONTEXT_A1)(a0)
    lw  a2, (CONTEXT_A2)(a0)
    lw  a3, (CONTEXT_A3)(a0)
    lw  a4, (CONTEXT_A4)(a0)
    lw  a5, (CONTEXT_A5)(a0)
    lw  a6, (CONTEXT_A6)(a0)
    lw  a7, (CONTEXT_A7)(a0)
    lw  t0, (CONTEXT_T0)(a0)
    lw  t1, (CONTEXT_T1)(a0)
    lw  t2, (CONTEXT_T2)(a0)
    lw  t3, (CONTEXT_T3)(a0)
    lw  t5, (CONTEXT_T5)(a0)
    lw  t6, (CONTEXT_T6)(a0)

    lw  s1, (CONTEXT_S1)(a0)
    lw  s2, (CONTEXT_S2)(a0)
    lw  s3, (CONTEXT_S3)(a0)
    lw  s4, (CONTEXT_S4)(a0)
    lw  s5, (CONTEXT_S5)(a0)
    lw  s6, (CONTEXT_S6)(a0)
    lw  s7, (CONTEXT_S7)(a0)
    lw  s8, (CONTEXT_S8)(a0)
    lw  s9, (CONTEXT_S9)(a0)
    lw  s10, (CONTEXT_S10)(a0)
    lw  s11, (CONTEXT_S11)(a0)

    lw  a0, (CONTEXT_A0)(a0)

LOCAL_LABEL(No_Restore_CONTEXT_INTEGER):

    lw  t1, CONTEXT_ContextFlags(t4)
    andi t1, t1, 0x1 << CONTEXT_CONTROL_BIT
    beqz t1, LOCAL_LABEL(No_Restore_CONTEXT_CONTROL)

    lw  ra, (CONTEXT_Ra)(t4)
    lw  t1, (CONTEXT_T4)(t4)
    lw  fp, (CONTEXT_Sp)(t4)
    sw  t1, -8(fp)
    lw  fp, (CONTEXT_Fp)(t4)
    lw  t1, (CONTEXT_Pc)(t4) // Since we cannot control $pc directly, we're going to corrupt t1
    lw  t4, (CONTEXT_Sp)(t4)
    addi sp, t4, -8
    lw  t4, (sp)
    addi sp, sp, 8
    jr  t1

LOCAL_LABEL(No_Restore_CONTEXT_CONTROL):
    lw  t4, (CONTEXT_T4)(t4)
    ret
LEAF_END RtlRestoreContext, _TEXT

// Incoming:
//  a0: Context*

LEAF_ENTRY RtlCaptureContext, _TEXT
    PROLOG_STACK_ALLOC 16
    sw  t1, 0(sp)
    li  t1, CONTEXT_FULL
    sw  t1, CONTEXT_ContextFlags(a0)
    lw  t1, 0(sp)
    EPILOG_STACK_FREE 16
    tail CONTEXT_CaptureContext
LEAF_END RtlCaptureContext, _TEXT

// Incoming:
//  a0: Context*
//

LEAF_ENTRY CONTEXT_CaptureContext, _TEXT
    PROLOG_STACK_ALLOC 32
    sw  t0, 0(sp)
    sw  t1, 4(sp)
    sw  t3, 8(sp)

    lw  t1, CONTEXT_ContextFlags(a0)
    li  t0, CONTEXT_CONTROL
    and  t3, t1, t0
    bne t3, t0, LOCAL_LABEL(Done_CONTEXT_CONTROL)

    addi  t0, sp, 16
    sw  fp, CONTEXT_Fp(a0)
    sw  t0, CONTEXT_Sp(a0)
    sw  ra, CONTEXT_Ra(a0)
    sw  ra, CONTEXT_Pc(a0)

LOCAL_LABEL(Done_CONTEXT_CONTROL):

    li  t0, CONTEXT_INTEGER
    and  t3, t1, t0
    bne  t3, t0, LOCAL_LABEL(Done_CONTEXT_INTEGER)

    lw  t0, 0(sp)
    lw  t1, 4(sp)
    lw  t3, 8(sp)

    sw  x0, (CONTEXT_X0)(a0)
    sw  tp, (CONTEXT_Tp)(a0)
    sw  gp, (CONTEXT_Gp)(a0)
    sw  a0, (CONTEXT_A0)(a0)
    sw  a1, (CONTEXT_A1)(a0)
    sw  a2, (CONTEXT_A2)(a0)
    sw  a3, (CONTEXT_A3)(a0)
    sw  a4, (CONTEXT_A4)(a0)
    sw  a5, (CONTEXT_A5)(a0)
    sw  a6, (CONTEXT_A6)(a0)
    sw  a7, (CONTEXT_A7)(a0)
    sw  t0, (CONTEXT_T0)(a0)
    sw  t1, (CONTEXT_T1)(a0)
    sw  t2, (CONTEXT_T2)(a0)
    sw  t3, (CONTEXT_T3)(a0)
    sw  t4, (CONTEXT_T4)(a0)
    sw  t5, (CONTEXT_T5)(a0)
    sw  t6, (CONTEXT_T6)(a0)

    sw  s1, (CONTEXT_S1)(a0)
    sw  s2, (CONTEXT_S2)(a0)
    sw  s3, (CONTEXT_S3)(a0)
    sw  s4, (CONTEXT_S4)(a0)
    sw  s5, (CONTEXT_S5)(a0)
    sw  s6, (CONTEXT_S6)(a0)
    sw  s7, (CONTEXT_S7)(a0)
    sw  s8, (CONTEXT_S8)(a0)
    sw  s9, (CONTEXT_S9)(a0)
    sw  s10, (CONTEXT_S10)(a0)
    sw  s11, (CONTEXT_S11)(a0)

LOCAL_LABEL(Done_CONTEXT_INTEGER):
    lw  t1, CONTEXT_ContextFlags(a0)

    li  t0, CONTEXT_FLOATING_POINT
    and  t3, t1, t0
    bne  t3, t0, LOCAL_LABEL(Done_CONTEXT_FLOATING_POINT)

    addi  a0, a0, CONTEXT_FPU_OFFSET

    fsw  f0, (CONTEXT_F0)(a0)
    fsw  f1, (CONTEXT_F1)(a0)
    fsw  f2, (CONTEXT_F2)(a0)
    fsw  f3, (CONTEXT_F3)(a0)
    fsw  f4, (CONTEXT_F4)(a0)
    fsw  f5, (CONTEXT_F5)(a0)
    fsw  f6, (CONTEXT_F6)(a0)
    fsw  f7, (CONTEXT_F7)(a0)
    fsw  f8, (CONTEXT_F8)(a0)
    fsw  f9, (CONTEXT_F9)(a0)
    fsw  f10, (CONTEXT_F10)(a0)
    fsw  f11, (CONTEXT_F11)(a0)
    fsw  f12, (CONTEXT_F12)(a0)
    fsw  f13, (CONTEXT_F13)(a0)
    fsw  f14, (CONTEXT_F14)(a0)
    fsw  f15, (CONTEXT_F15)(a0)
    fsw  f16, (CONTEXT_F16)(a0)
    fsw  f17, (CONTEXT_F17)(a0)
    fsw  f18, (CONTEXT_F18)(a0)
    fsw  f19, (CONTEXT_F19)(a0)
    fsw  f20, (CONTEXT_F20)(a0)
    fsw  f21, (CONTEXT_F21)(a0)
    fsw  f22, (CONTEXT_F22)(a0)
    fsw  f23, (CONTEXT_F23)(a0)
    fsw  f24, (CONTEXT_F24)(a0)
    fsw  f25, (CONTEXT_F25)(a0)
    fsw  f26, (CONTEXT_F26)(a0)
    fsw  f27, (CONTEXT_F27)(a0)
    fsw  f28, (CONTEXT_F28)(a0)
    fsw  f29, (CONTEXT_F29)(a0)
    fsw  f30, (CONTEXT_F30)(a0)
    fsw  f31, (CONTEXT_F31)(a0)

    frcsr t0
    sw  t0, (CONTEXT_FLOAT_CONTROL_OFFSET)(a0)

LOCAL_LABEL(Done_CONTEXT_FLOATING_POINT):

    EPILOG_STACK_FREE 16
    ret
LEAF_END CONTEXT_CaptureContext, _TEXT
