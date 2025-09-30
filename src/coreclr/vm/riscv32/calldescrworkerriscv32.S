// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

#include "unixasmmacros.inc"
#include "asmconstants.h"

//-----------------------------------------------------------------------------
// This helper routine enregisters the appropriate arguments and makes the
// actual call.
//-----------------------------------------------------------------------------
//void CallDescrWorkerInternal(CallDescrData * pCallDescrData);

NESTED_ENTRY CallDescrWorkerInternal, _TEXT, NoHandler
    PROLOG_SAVE_REG_PAIR_INDEXED  fp, ra, 0x10
    PROLOG_SAVE_REG s1, 8

    lw a1, CallDescrData__numStackSlots(a0)

    addi s1, a0, 0 // save pCallDescrData in s1
    beq a1, zero, LOCAL_LABEL(donestack)

    slli a2, a1, 3
    andi a0, a2, 0x4
    sub t4, sp, a0 // padding on high-addr
    add a0, a0, a2
    sub sp, sp, a0 // stack-16byte aligned

    lw a0, CallDescrData__pSrc(s1)

    add a2, a0, a2 // pSrcEnd=pSrc+4*numStackSlots

    // This loop copies numStackSlots words
    // from [pSrcEnd-8,pSrcEnd-16,...] to [sp-8,sp-16,...]
LOCAL_LABEL(stackloop):
    addi a2, a2, -4
    lw a4, 0(a2)
    addi t4, t4, -4
    sw a4, 0(t4)
    addi a1, a1, -1
    bne a1, zero, LOCAL_LABEL(stackloop)

LOCAL_LABEL(donestack):
    // If FP arguments are supplied in registers (t4 != NULL)
    lw t4, CallDescrData__pFloatArgumentRegisters(s1)
    beq t4, zero, LOCAL_LABEL(NoFloatingPoint)

    flw fa0, 0(t4)
    flw fa1, 4(t4)
    flw fa2, 8(t4)
    flw fa3, 12(t4)
    flw fa4, 16(t4)
    flw fa5, 20(t4)
    flw fa6, 24(t4)
    flw fa7, 28(t4)

LOCAL_LABEL(NoFloatingPoint):
    // Copy [pArgumentRegisters, ..., pArgumentRegisters + 56]
    // into a0, ..., a7
    lw t4, CallDescrData__pArgumentRegisters(s1)
    lw a0, 0(t4)
    lw a1, 4(t4)
    lw a2, 8(t4)
    lw a3, 12(t4)
    lw a4, 16(t4)
    lw a5, 20(t4)
    lw a6, 24(t4)
    lw a7, 28(t4)

    lw t4, CallDescrData__pTarget(s1)

    // call pTarget
    jalr t4
LOCAL_LABEL(CallDescrWorkerInternalReturnAddress):

    lw a3, CallDescrData__fpReturnSize(s1)

    beq a3, zero, LOCAL_LABEL(IntReturn)

    // Struct returned according to hardware floating-point calling convention.
    // Just save the returned registers (fa0, fa1/a0) and let CopyReturnedFpStructFromRegisters worry about placing
    // the fields as they were originally laid out in memory.

    fsw fa0, CallDescrData__returnValue(s1) // fa0 is always occupied; we have at least one floating field

    andi a3, a3, FpStruct__BothFloat
    bne  a3, zero, LOCAL_LABEL(SecondFieldFloatReturn)

    // The second returned register is integer (FpStruct::FloatInt | FpStruct::IntFloat)
    // Note: it will also go in here for FpStruct::OnlyOne but storing a register of trash doesn't hurt
    sw a0, (CallDescrData__returnValue + 4)(s1)
    j  LOCAL_LABEL(ReturnDone)

LOCAL_LABEL(SecondFieldFloatReturn):
    fsw fa1, (CallDescrData__returnValue + 4)(s1)
    j  LOCAL_LABEL(ReturnDone)

LOCAL_LABEL(IntReturn):
    // Save struct returned according to integer calling convention
    sw  a0, CallDescrData__returnValue(s1)
    sw  a1, (CallDescrData__returnValue + 4)(s1)

LOCAL_LABEL(ReturnDone):
    EPILOG_STACK_RESTORE
    EPILOG_RESTORE_REG  s1, 8
    EPILOG_RESTORE_REG_PAIR_INDEXED  fp, ra, 0x10
    ret

PATCH_LABEL CallDescrWorkerInternalReturnAddressOffset
    .quad LOCAL_LABEL(CallDescrWorkerInternalReturnAddress) - C_FUNC(CallDescrWorkerInternal)

NESTED_END CallDescrWorkerInternal, _TEXT
