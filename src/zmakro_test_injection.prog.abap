*&---------------------------------------------------------------------*
*&  Include           ZMAKRO_TEST_INJECTION
*&---------------------------------------------------------------------*

DEFINE create_injection.

  CREATE OBJECT ztest_injection=>self.

END-OF-DEFINITION.

DEFINE call_injection.
* call a macro with a active injection
* &1 injection name
* &2 called macro

  in_set_active &1.
  &2.
  in_set_active &1.

END-OF-DEFINITION.

DEFINE in_set_active.
* activate injection
* &1 injection

  ztest_injection=>self->injection_set_active( &1 ).

END-OF-DEFINITION.

DEFINE in_set_inactive.
* deactivate injection
* &1 die Injektion

  ztest_injection=>self->injection_set_inactive( &1 ).

END-OF-DEFINITION.

DEFINE injection_active.
* check injection is active
* &1 injection name

  IF ztest_injection=>injection_is_active( &1 ) = abap_true.

END-OF-DEFINITION.
