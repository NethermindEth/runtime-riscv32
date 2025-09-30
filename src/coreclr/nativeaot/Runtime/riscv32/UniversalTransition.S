// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

#include <unixasmmacros.inc>

#ifdef _DEBUG
#define TRASH_SAVED_ARGUMENT_REGISTERS
#endif

#ifdef TRASH_SAVED_ARGUMENT_REGISTERS
    .global RhpIntegerTrashValues
    .global RhpFpTrashValues
#endif // TRASH_SAVED_ARGUMENT_REGISTERS

// Padding to account for the odd number of saved integer registers
#define ALIGNMENT_PADDING_SIZE (8)

#define COUNT_ARG_REGISTERS (8)
#define INTEGER_REGISTER_SIZE (4)
#define ARGUMENT_REGISTERS_SIZE (COUNT_ARG_REGISTERS * INTEGER_REGISTER_SIZE)

// Largest return block is 4 floats
#define RETURN_BLOCK_SIZE (16)

#define COUNT_FLOAT_ARG_REGISTERS (8)
#define FLOAT_REGISTER_SIZE (4)
#define FLOAT_ARG_REGISTERS_SIZE (COUNT_FLOAT_ARG_REGISTERS * FLOAT_REGISTER_SIZE)

#define PUSHED_RA_SIZE (4)
#define PUSHED_FP_SIZE (4)

// From CallerSP to ChildSP, the stack frame is composed of the following adjacent regions:
//
//      ALIGNMENT_PADDING_SIZE
//      ARGUMENT_REGISTERS_SIZE
//      RETURN_BLOCK_SIZE
//      FLOAT_ARG_REGISTERS_SIZE
//      PUSHED_RA_SIZE
//      PUSHED_FP_SIZE
//

#define DISTANCE_FROM_CHILDSP_TO_RETURN_BLOCK (PUSHED_FP_SIZE + PUSHED_RA_SIZE + FLOAT_ARG_REGISTERS_SIZE)

#define STACK_SIZE (ALIGNMENT_PADDING_SIZE + ARGUMENT_REGISTERS_SIZE + RETURN_BLOCK_SIZE + FLOAT_ARG_REGISTERS_SIZE + PUSHED_RA_SIZE + PUSHED_FP_SIZE)

#define FLOAT_ARG_OFFSET (PUSHED_FP_SIZE + PUSHED_RA_SIZE)
#define ARGUMENT_REGISTERS_OFFSET (FLOAT_ARG_OFFSET + FLOAT_ARG_REGISTERS_SIZE + RETURN_BLOCK_SIZE)

//
// RhpUniversalTransition
//
// At input to this function, a0-a7, fa0-fa7, and the stack may contain any number of arguments.
//
// In addition, there are 2 extra arguments passed in the intra-procedure-call scratch register:
//  t0 will contain the managed function that is to be called by this transition function
//  t1 will contain the pointer-sized extra argument to the managed function
//
// When invoking the callee:
//
//  a0 shall contain a pointer to the TransitionBlock
//  a1 shall contain the value that was in t1 at entry to this function
//
// Frame layout is:
//
//  {StackPassedArgs}                           ChildSP+100     CallerSP+000
//  {AlignmentPad (0x8 bytes)}                  ChildSP+0F8     CallerSP-008
//  {IntArgRegs (a0-a7) (0x40 bytes)}           ChildSP+0B8     CallerSP-048
//  {ReturnBlock (0x20 bytes)}                  ChildSP+098     CallerSP-068
//   -- The base address of the Return block is the TransitionBlock pointer, the floating point args are
//      in the neg space of the TransitionBlock pointer.  Note that the callee has knowledge of the exact
//      layout of all pieces of the frame that lie at or above the pushed floating point registers.
//  {FpArgRegs (fa0-fa7) (0x40 bytes)}          ChildSP+058     CallerSP-0A8
//  {PushedRA}                                  ChildSP+008     CallerSP-0F8
//  {PushedFP}                                  ChildSP+000     CallerSP-100
//
// NOTE: If the frame layout ever changes, the C++ UniversalTransitionStackFrame structure
// must be updated as well.
//
// NOTE: The callee receives a pointer to the base of the ReturnBlock, and the callee has
// knowledge of the exact layout of all pieces of the frame that lie at or above the pushed
// FpArgRegs.
//
// NOTE: The stack walker guarantees that conservative GC reporting will be applied to
// everything between the base of the ReturnBlock and the top of the StackPassedArgs.
//

    .text

    .macro UNIVERSAL_TRANSITION FunctionName

    NESTED_ENTRY Rhp\FunctionName, _TEXT, NoHandler

        # FP and RA registers
        addi        sp, sp, -STACK_SIZE
        sw          s0, 0x0(sp)       # Save frame pointer
        sw          ra, 0x04(sp)      # Save return address

        # Floating point registers
        fsw         fa0, FLOAT_ARG_OFFSET(sp)
        fsw         fa1, FLOAT_ARG_OFFSET + 0x04(sp)
        fsw         fa2, FLOAT_ARG_OFFSET + 0x08(sp)
        fsw         fa3, FLOAT_ARG_OFFSET + 0x18(sp)
        fsw         fa4, FLOAT_ARG_OFFSET + 0x1c(sp)
        fsw         fa5, FLOAT_ARG_OFFSET + 0x20(sp)
        fsw         fa6, FLOAT_ARG_OFFSET + 0x24(sp)
        fsw         fa7, FLOAT_ARG_OFFSET + 0x28(sp)

        # Space for return buffer data (0x40 bytes)

        # Save argument registers
        sw          a0, ARGUMENT_REGISTERS_OFFSET(sp)
        sw          a1, ARGUMENT_REGISTERS_OFFSET + 0x04(sp)
        sw          a2, ARGUMENT_REGISTERS_OFFSET + 0x08(sp)
        sw          a3, ARGUMENT_REGISTERS_OFFSET + 0x0c(sp)
        sw          a4, ARGUMENT_REGISTERS_OFFSET + 0x10(sp)
        sw          a5, ARGUMENT_REGISTERS_OFFSET + 0x14(sp)
        sw          a6, ARGUMENT_REGISTERS_OFFSET + 0x18(sp)
        sw          a7, ARGUMENT_REGISTERS_OFFSET + 0x1c(sp)

#ifdef TRASH_SAVED_ARGUMENT_REGISTERS
        PREPARE_EXTERNAL_VAR RhpFpTrashValues, a1

        flw fa0, 0x00(a1)
        flw fa1, 0x04(a1)
        flw fa2, 0x08(a1)
        flw fa3, 0x0c(a1)
        flw fa4, 0x10(a1)
        flw fa5, 0x14(a1)
        flw fa6, 0x18(a1)
        flw fa7, 0x1c(a1)

        PREPARE_EXTERNAL_VAR RhpIntegerTrashValues, a1

        lw a2, 0x8(a1)
        lw a3, 0xc(a1)
        lw a4, 0x10(a1)
        lw a5, 0x14(a1)
        lw a6, 0x18(a1)
        lw a7, 0x1c(a1)
#endif // TRASH_SAVED_ARGUMENT_REGISTERS

        add         a0, sp, DISTANCE_FROM_CHILDSP_TO_RETURN_BLOCK  # First parameter to target function is a pointer to the return block
        mv          a1, t1                                         # Second parameter to target function
        jalr        ra, t0, 0

ALTERNATE_ENTRY ReturnFrom\FunctionName

        # Move the result (the target address) to a2 so it doesnt get overridden when we restore the
        # argument registers.
        mv          t2, a0

        # Restore floating point registers
        flw         fa0, FLOAT_ARG_OFFSET(sp)
        flw         fa1, FLOAT_ARG_OFFSET + 0x04(sp)
        flw         fa2, FLOAT_ARG_OFFSET + 0x08(sp)
        flw         fa3, FLOAT_ARG_OFFSET + 0x0c(sp)
        flw         fa4, FLOAT_ARG_OFFSET + 0x10(sp)
        flw         fa5, FLOAT_ARG_OFFSET + 0x14(sp)
        flw         fa6, FLOAT_ARG_OFFSET + 0x18(sp)
        flw         fa7, FLOAT_ARG_OFFSET + 0x1c(sp)

        # Restore the argument registers
        lw          a0, ARGUMENT_REGISTERS_OFFSET(sp)
        lw          a1, ARGUMENT_REGISTERS_OFFSET + 0x04(sp)
        lw          a2, ARGUMENT_REGISTERS_OFFSET + 0x08(sp)
        lw          a3, ARGUMENT_REGISTERS_OFFSET + 0x0c(sp)
        lw          a4, ARGUMENT_REGISTERS_OFFSET + 0x10(sp)
        lw          a5, ARGUMENT_REGISTERS_OFFSET + 0x14(sp)
        lw          a6, ARGUMENT_REGISTERS_OFFSET + 0x18(sp)
        lw          a7, ARGUMENT_REGISTERS_OFFSET + 0x1c(sp)

        # Restore FP and RA registers, and free the allocated stack block
        lw          ra, 0x04(sp)
        lw          s0, 0x0(sp)
        addi        sp, sp, STACK_SIZE

        # Tailcall to the target address.
        jr          t2

    NESTED_END Rhp\FunctionName, _TEXT

    .endm

    // To enable proper step-in behavior in the debugger, we need to have two instances
    // of the thunk. For the first one, the debugger steps into the call in the function,
    // for the other, it steps over it.
    UNIVERSAL_TRANSITION UniversalTransition
    UNIVERSAL_TRANSITION UniversalTransition_DebugStepTailCall
