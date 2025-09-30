// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

#include "unixasmmacros.inc"
#include "asmconstants.h"

//////////////////////////////////////////////////////////////////////////
//
// This function creates a stack frame right below the target frame, restores all callee
// saved registers, SP, and RA from the passed in context.
// Then it uses the ThrowExceptionHelper to throw the passed in exception from that context.
// EXTERN_C void ThrowExceptionFromContextInternal(CONTEXT* context, PAL_SEHException* ex);
LEAF_ENTRY ThrowExceptionFromContextInternal, _TEXT
#ifdef HAS_ASAN
#pragma error("TODO-RISCV32-CQ: unimplemented on RISCV32 yet")
#endif
    addi  sp, sp, -8
    .cfi_adjust_cfa_offset 8

    // Save the FP & RA to the stack so that the unwind can work at the instruction after
    // loading the FP from the context, but before loading the SP from the context.
    sw  fp, 0(sp)
    sw  ra, 4(sp)
    .cfi_rel_offset fp, 0
    .cfi_rel_offset ra, 4

    lw  tp, CONTEXT_Tp(a0)
    lw  gp, CONTEXT_Gp(a0)
    lw  s1, CONTEXT_S1(a0)
    lw  s2, CONTEXT_S2(a0)
    lw  s3, CONTEXT_S3(a0)
    lw  s4, CONTEXT_S4(a0)
    lw  s5, CONTEXT_S5(a0)
    lw  s6, CONTEXT_S6(a0)
    lw  s7, CONTEXT_S7(a0)
    lw  s8, CONTEXT_S8(a0)
    lw  s9, CONTEXT_S9(a0)
    lw  s10, CONTEXT_S10(a0)
    lw  s11, CONTEXT_S11(a0)
    lw  ra, CONTEXT_Ra(a0)

    lw  fp, CONTEXT_Fp(a0)
    lw  sp, CONTEXT_Sp(a0)

    // The PAL_SEHException pointer
    addi a0, a1, 0
    tail ThrowExceptionHelper
LEAF_END ThrowExceptionFromContextInternal, _TEXT
