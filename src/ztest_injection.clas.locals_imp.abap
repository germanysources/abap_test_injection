CLASS callstack DEFINITION INHERITING FROM ztesT_injection FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PUBLIC SECTION.

  METHODS constructor
    RAISING cx_program_not_found.

  PRIVATE SECTION.

  CLASS-METHODS class_setup
    RAISING cx_program_not_found.

  METHODS setup
    RAISING cx_program_not_found.

  METHODS teardown
    RAISING cx_program_not_found.

  CLASS-METHODS class_teardown
    RAISING cx_program_not_found.

  METHODS activ_deactiv FOR TESTING
    RAISING cx_program_not_found.

  METHODS exception_test
    RAISING cx_program_not_found.

ENDCLASS.

CLASS callstack IMPLEMENTATION.

  METHOD exception_test.

    " no exception cx_program_not_found occurs
    CREATE OBJECT self.
    self->injection_set_active( name = 'UNIT1' ).
    self->injection_set_inactive( name = 'UNIT1' ).

  ENDMETHOD.

  METHOD class_setup.
    DATA: inj TYPE REF TO ztest_injection.

    CREATE OBJECT inj.
    inj->injection_set_active( name = 'UNIT1' ).
    inj->injection_set_inactive( name = 'UNIT1' ).

  ENDMETHOD.

  METHOD setup.
    exception_test( ).
  ENDMETHOD.

  METHOD constructor.
    super->constructor( ).
    exception_test( ).
  ENDMETHOD.

  METHOD activ_deactiv.
* activate and deactivate
    DATA: caller TYPE cl_abap_get_call_stack=>formatted_entry,
          is_active TYPE sap_bool,
          stack TYPE cl_abap_get_call_stack=>call_stack_internal,
           formatted_stack TYPE cl_abap_get_call_stack=>formatted_entry_stack.
    FIELD-SYMBOLS: <stack> TYPE cl_abap_get_call_stack=>formatted_entry.

    CREATE OBJECT self.
    self->injection_set_active( name = 'UNIT1' ).

    is_active = injection_is_active( EXPORTING name = 'UNIT1' IMPORTING caller = caller ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true act = is_active msg = 'Injektion ist nicht aktiv nach aktivieren' ).

    stack = cl_abap_get_call_stack=>get_call_stack( ).
    formatted_stack = cl_abap_get_call_stack=>format_call_stack_with_struct( EXPORTING stack = stack ).
    READ TABLE formatted_stack ASSIGNING <stack> INDEX 1.
    cl_abap_unit_assert=>assert_equals( exp = <stack>-progname act = caller-progname msg = 'Programmname Aufrufer stimmt nicht' ).
    cl_abap_unit_assert=>assert_equals( exp = <stack>-includename act = caller-includename msg = 'Programmname Aufrufer stimmt nicht' ).

    self->injection_set_inactive( name = 'UNIT1' ).
    is_active = injection_is_active( EXPORTING name = 'UNIT1' IMPORTING caller = caller ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = is_active msg = 'Injektion ist weiterhin aktiv nach deaktivieren' ).

  ENDMETHOD.

  METHOD teardown.
    exception_test( ).
  ENDMETHOD.

  METHOD class_teardown.
    DATA: inj TYPE REF TO ztest_injection.

    CREATE OBJECT inj.
    inj->injection_set_active( name = 'UNIT1' ).
    inj->injection_set_inactive( name = 'UNIT1' ).

  ENDMETHOD.

ENDCLASS.
