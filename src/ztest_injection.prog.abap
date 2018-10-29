*&---------------------------------------------------------------------*
*& Report  ZTEST_INJECTION
*& unit test for injection. Not called from a testclass. It shouldn't fail.
*&---------------------------------------------------------------------*
REPORT ZTEST_INJECTION.

START-OF-SELECTION.

  CREATE OBJECT ztest_injection=>self.

  TRY.
    ztest_injection=>self->injection_set_active( name = 'GH' ).
    ASSert 1 = 0.
    ##NO_HANDLER
  CATCH cx_program_not_found.
  ENDTRY.

  DATA(is_active) = ztest_injection=>injection_is_active( name = 'GH' ).
  assert is_active = abap_false.
