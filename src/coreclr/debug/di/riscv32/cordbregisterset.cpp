// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

//*****************************************************************************
// File: CordbRegisterSet.cpp
//

//
//*****************************************************************************
#include "primitives.h"


HRESULT CordbRegisterSet::GetRegistersAvailable(ULONG64* pAvailable)
{
    FAIL_IF_NEUTERED(this);
    VALIDATE_POINTER_TO_OBJECT(pAvailable, ULONG64 *);

    *pAvailable = SETBITULONG64(REGISTER_RISCV32_PC)
                | SETBITULONG64(REGISTER_RISCV32_RA)
                | SETBITULONG64(REGISTER_RISCV32_SP)
                | SETBITULONG64(REGISTER_RISCV32_GP)
                | SETBITULONG64(REGISTER_RISCV32_TP)
                | SETBITULONG64(REGISTER_RISCV32_T0)
                | SETBITULONG64(REGISTER_RISCV32_T1)
                | SETBITULONG64(REGISTER_RISCV32_T2)
                | SETBITULONG64(REGISTER_RISCV32_FP)
                | SETBITULONG64(REGISTER_RISCV32_S1)
                | SETBITULONG64(REGISTER_RISCV32_A0)
                | SETBITULONG64(REGISTER_RISCV32_A1)
                | SETBITULONG64(REGISTER_RISCV32_A2)
                | SETBITULONG64(REGISTER_RISCV32_A3)
                | SETBITULONG64(REGISTER_RISCV32_A4)
                | SETBITULONG64(REGISTER_RISCV32_A5)
                | SETBITULONG64(REGISTER_RISCV32_A6)
                | SETBITULONG64(REGISTER_RISCV32_A7)
                | SETBITULONG64(REGISTER_RISCV32_S2)
                | SETBITULONG64(REGISTER_RISCV32_S3)
                | SETBITULONG64(REGISTER_RISCV32_S4)
                | SETBITULONG64(REGISTER_RISCV32_S5)
                | SETBITULONG64(REGISTER_RISCV32_S6)
                | SETBITULONG64(REGISTER_RISCV32_S7)
                | SETBITULONG64(REGISTER_RISCV32_S8)
                | SETBITULONG64(REGISTER_RISCV32_S9)
                | SETBITULONG64(REGISTER_RISCV32_S10)
                | SETBITULONG64(REGISTER_RISCV32_S11)
                | SETBITULONG64(REGISTER_RISCV32_T3)
                | SETBITULONG64(REGISTER_RISCV32_T4)
                | SETBITULONG64(REGISTER_RISCV32_T5)
                | SETBITULONG64(REGISTER_RISCV32_T6)
                | SETBITULONG64(REGISTER_RISCV32_F0)
                | SETBITULONG64(REGISTER_RISCV32_F1)
                | SETBITULONG64(REGISTER_RISCV32_F2)
                | SETBITULONG64(REGISTER_RISCV32_F3)
                | SETBITULONG64(REGISTER_RISCV32_F4)
                | SETBITULONG64(REGISTER_RISCV32_F5)
                | SETBITULONG64(REGISTER_RISCV32_F6)
                | SETBITULONG64(REGISTER_RISCV32_F7)
                | SETBITULONG64(REGISTER_RISCV32_F8)
                | SETBITULONG64(REGISTER_RISCV32_F9)
                | SETBITULONG64(REGISTER_RISCV32_F10)
                | SETBITULONG64(REGISTER_RISCV32_F11)
                | SETBITULONG64(REGISTER_RISCV32_F12)
                | SETBITULONG64(REGISTER_RISCV32_F13)
                | SETBITULONG64(REGISTER_RISCV32_F14)
                | SETBITULONG64(REGISTER_RISCV32_F15)
                | SETBITULONG64(REGISTER_RISCV32_F16)
                | SETBITULONG64(REGISTER_RISCV32_F17)
                | SETBITULONG64(REGISTER_RISCV32_F18)
                | SETBITULONG64(REGISTER_RISCV32_F19)
                | SETBITULONG64(REGISTER_RISCV32_F20)
                | SETBITULONG64(REGISTER_RISCV32_F21)
                | SETBITULONG64(REGISTER_RISCV32_F22)
                | SETBITULONG64(REGISTER_RISCV32_F23)
                | SETBITULONG64(REGISTER_RISCV32_F24)
                | SETBITULONG64(REGISTER_RISCV32_F25)
                | SETBITULONG64(REGISTER_RISCV32_F26)
                | SETBITULONG64(REGISTER_RISCV32_F27)
                | SETBITULONG64(REGISTER_RISCV32_F28)
                | SETBITULONG64(REGISTER_RISCV32_F29)
                | SETBITULONG64(REGISTER_RISCV32_F30)
                | SETBITULONG64(REGISTER_RISCV32_F31);

    return S_OK;
}

HRESULT CordbRegisterSet::GetRegisters(ULONG64 mask, ULONG32 regCount,
                                       CORDB_REGISTER regBuffer[])
{
    _ASSERTE(!"RISCV32:NYI");
    return S_OK;
}


HRESULT CordbRegisterSet::GetRegistersAvailable(ULONG32 regCount,
                                                BYTE    pAvailable[])
{
    _ASSERTE(!"RISCV32:NYI");
    return S_OK;
}


HRESULT CordbRegisterSet::GetRegisters(ULONG32 maskCount, BYTE mask[],
                                       ULONG32 regCount, CORDB_REGISTER regBuffer[])
{
    _ASSERTE(!"RISCV32:NYI");
    return S_OK;
}


// This is just a convenience function to convert a regdisplay into a Context.
// Since a context has more info than a regdisplay, the conversion isn't perfect
// and the context can't be fully accurate.
void CordbRegisterSet::InternalCopyRDToContext(DT_CONTEXT *pInputContext)
{
    _ASSERTE(!"RISCV32:NYI");
}
