* Test Injektion ABAP
* Copyright (C) 2017 Johannes Gerbershagen
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU LESSER General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
*  This program is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU LESSER General Public License for more details.

class ZTEST_INJECTION definition
  public
  create public .

public section.

  types INJECTION type CHAR30 .
  types:
    BEGIN OF activ_stack,
    injection TYPE injection.
    INCLUDE TYPE CL_ABAP_GET_CALL_STACK=>FORMATTED_ENTRY.
  TYPES END OF activ_stack .

  class-data SELF type ref to ZTEST_INJECTION .

  methods INJECTION_SET_ACTIVE
    importing
      !NAME type INJECTION
    raising
      CX_PROGRAM_NOT_FOUND .
  methods INJECTION_SET_INACTIVE
    importing
      !NAME type INJECTION .
  class-methods INJECTION_IS_ACTIVE
    importing
      !NAME type INJECTION
    exporting
      !CALLER type CL_ABAP_GET_CALL_STACK=>FORMATTED_ENTRY
    returning
      value(IS_ACTIVE) type SAP_BOOL .
  class-methods GET_INSTANCE
    RETURNING VALUE(instance) TYPE REF TO ztest_injection.
protected section.

  data:
    activ_injections TYPE SORTED TABLE OF activ_stack
    WITH UNIQUE KEY injection.

  methods GET_TESTCLASS
    exporting
      !CALLER type CL_ABAP_GET_CALL_STACK=>FORMATTED_ENTRY
    raising
      CX_PROGRAM_NOT_FOUND .
private section.
ENDCLASS.



CLASS ZTEST_INJECTION IMPLEMENTATION.


  method GET_INSTANCE.

    IF self IS NOT BOUND.
      CREATE OBJECT self.
    ENDIF.

    instance = self.

  endmethod.


  method GET_TESTCLASS.

    DATA:  stack TYPE cl_abap_get_call_stack=>call_stack_internal,
           formatted_stack TYPE cl_abap_get_call_stack=>formatted_entry_stack,
           get_include TYPE REF TO if_oo_class_incl_naming,
           next TYPE sap_bool,
           classname TYPE seoclass-clsname.
    FIELD-SYMBOLS: <stack> TYPE cl_abap_get_call_stack=>formatted_entry.

    stack = cl_abap_get_call_stack=>get_call_stack( ).
    formatted_stack = cl_abap_get_call_stack=>format_call_stack_with_struct( EXPORTING stack = stack ).
* searches in stack, if method was called while executing a testclass.
* Assumes, that testclasses are executed from the following stack:
*kind=METHOD
*progname=CL_AUNIT_TEST_CLASS===========CP
*event: a method of CL_AUNIT_TEST_CLASS=>if_aunit_test_class_handle

    LOOP AT formatted_stack TRANSPORTING NO FIELDS
      WHERE kind = 'METHOD' AND progname = 'CL_AUNIT_TEST_CLASS===========CP'
      AND event CS 'CL_AUNIT_TEST_CLASS=>IF_AUNIT_TEST_CLASS_HANDLE'.

    ENDLOOP.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_program_not_found.
    ENDIF.

* find method which calls ztest_injection=>injection_set_active
    classname = cl_abap_classdescr=>get_class_name( me ).
    Replace FIRST OCCURRENCE OF '\CLASS=' IN classname WITH space.
    CONDENSE classname.
    get_include ?= cl_oo_include_naming=>get_instance_by_name( classname ).
    LOOP AT formatted_stack ASSIGNING <stack> FROM 2.

      IF next = abap_true.
        " This is the caller
        caller = <stack>.
        EXIT.
      ENDIF.
      IF ( <stack>-kind = 'METHOD' AND <stack>-progname = sy-repid
        AND <stack>-includename = conv tpda_include( get_include->get_include_by_mtdname( 'INJECTION_SET_ACTIVE' ) ) ).
        next = abap_true.
      ENDIF.

    ENDLOOP.

  endmethod.


  METHOD injection_is_active.
    FIELD-SYMBOLS: <activ_injection> TYPE activ_stack.

    is_active = abap_false.
    IF self IS NOT BOUND.
      RETURN.
    ENDIF.
    TRY.
        self->get_testclass( ).
        READ TABLE self->activ_injections ASSIGNING <activ_injection> WITH KEY injection = name.
        IF sy-subrc = 0.
          ##ENH_OK
          MOVE-CORRESPONDING <activ_injection> TO caller.
          is_active = abap_true.
        ENDIF.
        ##NO_HANDLER
      CATCH cx_program_not_found.
    ENDTRY.

  ENDMETHOD.


  method INJECTION_SET_ACTIVE.

    DATA: caller TYPE CL_ABAP_GET_CALL_STACK=>FORMATTED_ENTRY,
          new_injection TYPE activ_stack.

    get_testclass( IMPORTING caller = caller ).
    new_injection-injection = name.
    ##ENH_OK
    MOVE-CORRESPONDING caller TO new_injection.

    INSERT new_injection INTO TABLE activ_injections.
    ASSERT sy-subrc = 0. " developer error injection is already active

  endmethod.


  METHOD injection_set_inactive.
* deactivate Injection, delete it from itab activ_injections
    DATA: injection TYPE activ_stack.

    injection-injection = name.
    DELETE TABLE activ_injections FROM injection.
    " IF sy-subrc <> 0.
    " injection is already inactive

  ENDMETHOD.
ENDCLASS.
