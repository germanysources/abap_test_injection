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
protected section.

  data:
* Pro Klasse=>Methode ist nur eine aktive Test-Injection moeglich
    activ_injections TYPE SORTED TABLE OF activ_stack
    WITH UNIQUE KEY injection.
  CLASS-DATA actual_name TYPE injection. " aktueller Name Test-Injektion

  methods GET_TESTCLASS
    exporting
      !CALLER type CL_ABAP_GET_CALL_STACK=>FORMATTED_ENTRY
    raising
      CX_PROGRAM_NOT_FOUND .
private section.
ENDCLASS.



CLASS ZTEST_INJECTION IMPLEMENTATION.


  method GET_TESTCLASS.

    DATA:  stack TYPE cl_abap_get_call_stack=>call_stack_internal,
           formatted_stack TYPE cl_abap_get_call_stack=>formatted_entry_stack,
           get_include TYPE REF TO if_oo_class_incl_naming,
           next TYPE sap_bool,
           classname TYPE seoclass-clsname.
    FIELD-SYMBOLS: <stack> TYPE cl_abap_get_call_stack=>formatted_entry.

    stack = cl_abap_get_call_stack=>get_call_stack( ).
    formatted_stack = cl_abap_get_call_stack=>format_call_stack_with_struct( EXPORTING stack = stack ).
* Jetzt letzte Position suchen, ob Aufruf einer Testklasse erfolgt ist
*kind=EVENT
*progname=RS_AUNIT_CLASSTEST_SESSION
*includename=RS_AUNIT_CLASSTEST_SESSION
*event=start-of-selection

    READ TABLE formatted_stack ASSIGNING <stack> INDEX lines( formatted_stack ).
    IF NOT ( <stack>-kind = 'EVENT' AND <stack>-progname = 'RS_AUNIT_CLASSTEST_SESSION' AND <stack>-includename
      = <stack>-progname AND <stack>-event = 'START-OF-SELECTION' ).
      RAISE EXCEPTION TYPE cx_program_not_found.
    ENDIF.

* letzte Methode bevor diese ztest_injection=>injection_set_active gerufen wird
    classname = cl_abap_classdescr=>get_class_name( me ).
    Replace FIRST OCCURRENCE OF '\CLASS=' IN classname WITH space.
    CONDENSE classname.
    get_include ?= cl_oo_include_naming=>get_instance_by_name( classname ).
    LOOP AT formatted_stack ASSIGNING <stack> FROM 2.

      IF next = abap_true.
        " Das ist der Aufrufer, der die Test-Injektion aktiviert
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
    ASSERT sy-subrc = 0. " sonst ist die Test-Injektion bereits aktiv
    " d.h. fehlerhafter Source-Code

  endmethod.


  METHOD injection_set_inactive.
* Injektion deaktivieren, d.h. aus Tabelle activ_injections loeschen
* Wenn Aufrufer mitgegeben wurde, wird nur der Aufrufer geloescht
* sonst werden alle Injektionen mit dem Namen name geloescht
    DATA: injection TYPE activ_stack.

    injection-injection = name.
    DELETE TABLE activ_injections FROM injection.
    " IF sy-subrc <> 0.
    " Injektion ist bereits deaktiviert

  ENDMETHOD.
ENDCLASS.
