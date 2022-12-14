CLASS zcl_bc_text_toolkit DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      tt_fieldname TYPE STANDARD TABLE OF fieldname WITH EMPTY KEY,
      tt_string    TYPE STANDARD TABLE OF string.

    CONSTANTS:
      c_alphanumeric TYPE string VALUE `1234567890qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM `.

    CLASS-METHODS are_texts_same_ignoring_case
      IMPORTING
        !iv_text1      TYPE clike
        !iv_text2      TYPE clike
      RETURNING
        VALUE(rv_same) TYPE abap_bool.

    CLASS-METHODS ends_with
      IMPORTING !text         TYPE clike
                !suffix       TYPE clike
      RETURNING VALUE(output) TYPE abap_bool.

    CLASS-METHODS get_exception_text_recursively
      IMPORTING !io_cx   TYPE REF TO cx_root
      CHANGING  !ct_text TYPE hdb_tab_string.

    CLASS-METHODS get_shortest_text
      IMPORTING
        !it_candidate       TYPE tt_string
        !iv_ignore_if_empty TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(rv_shortest)  TYPE string .

    CLASS-METHODS get_text_after_separator
      IMPORTING
        !iv_text       TYPE clike
        !iv_separator  TYPE clike
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS is_string_an_integer
      IMPORTING
        !iv_string   TYPE string
      RETURNING
        VALUE(rv_is) TYPE abap_bool .

    CLASS-METHODS lower_case
      IMPORTING !iv_input        TYPE clike
      RETURNING VALUE(rv_output) TYPE string.

    CLASS-METHODS remove_non_alphanum_chars
      IMPORTING
        !iv_valid_chars TYPE clike OPTIONAL
      CHANGING
        !cv_text        TYPE clike .

    CLASS-METHODS remove_risky_characters
      IMPORTING !iv_string       TYPE clike
                !iv_no_space     TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(rv_result) TYPE string.

    CLASS-METHODS remove_text_in_string
      IMPORTING
        !iv_string       TYPE clike
        !iv_remove       TYPE clike
      RETURNING
        VALUE(rv_result) TYPE string .

    CLASS-METHODS replace_turkish_characters
      CHANGING
        !cv_text TYPE clike .

    CLASS-METHODS replace_turkish_chars_in_itab
      IMPORTING
        !ir_itab   TYPE REF TO data
        !it_fields TYPE tt_fieldname.

    CLASS-METHODS upper_case
      IMPORTING !iv_input        TYPE clike
      RETURNING VALUE(rv_output) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_bc_text_toolkit IMPLEMENTATION.

  METHOD are_texts_same_ignoring_case.
    DATA(lv_text1_upper) = |{ iv_text1 }|.
    TRANSLATE lv_text1_upper TO UPPER CASE.

    DATA(lv_text2_upper) = |{ iv_text2 }|.
    TRANSLATE lv_text2_upper TO UPPER CASE.

    rv_same = xsdbool( lv_text1_upper EQ lv_text2_upper ).
  ENDMETHOD.


  METHOD ends_with.
    CHECK text   IS NOT INITIAL AND
          suffix IS NOT INITIAL.

    DATA(tlen) = strlen( text ).
    DATA(slen) = strlen( suffix ).

    IF tlen < slen.
      RETURN.
    ENDIF.

    DATA(start_pos) = tlen - slen.
    output = xsdbool( text+start_pos(slen) = suffix ).
  ENDMETHOD.


  METHOD get_exception_text_recursively.
    IF io_cx->previous IS NOT INITIAL.
      get_exception_text_recursively( EXPORTING io_cx   = io_cx->previous
                                      CHANGING  ct_text = ct_text ).
    ENDIF.

    APPEND |{ io_cx->get_text( ) }| TO ct_text.
  ENDMETHOD.


  METHOD get_shortest_text.
    rv_shortest = ycl_addict_text_toolkit=>get_shortest_text(
        candidates      = it_candidate
        ignore_if_empty = iv_ignore_if_empty ).
  ENDMETHOD.


  METHOD get_text_after_separator.
    DATA lt_split TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    CHECK iv_text IS NOT INITIAL.
    SPLIT iv_text AT iv_separator INTO TABLE lt_split.

    IF lines( lt_split ) LE 0.
      RETURN.
    ENDIF.

    rv_text = lt_split[ lines( lt_split ) ].
  ENDMETHOD.


  METHOD is_string_an_integer.
    DATA lv_int TYPE i.

    CHECK iv_string IS NOT INITIAL.

    TRY.
        MOVE EXACT iv_string TO lv_int.
        rv_is = abap_true.
      CATCH cx_root.
        rv_is = abap_false.
    ENDTRY.
  ENDMETHOD.


  METHOD lower_case.
    rv_output = iv_input.
    TRANSLATE rv_output TO LOWER CASE.
  ENDMETHOD.


  METHOD remove_non_alphanum_chars.
    DATA(lv_output) = CONV string( space ).
    DATA(lv_length) = strlen( cv_text ).
    DATA(lv_pos) = 0.

    WHILE lv_pos LT lv_length.
      DATA(lv_char) = CONV string( cv_text+lv_pos(1) ).
      IF lv_char CA c_alphanumeric OR
         ( iv_valid_chars IS NOT INITIAL AND
           lv_char CA iv_valid_chars
         ).
        lv_output = |{ lv_output }{ lv_char }|.
      ELSE.
        lv_output = |{ lv_output } |.
      ENDIF.

      ADD 1 TO lv_pos.
    ENDWHILE.

    cv_text = lv_output.
  ENDMETHOD.


  METHOD remove_risky_characters.
    rv_result = iv_string.
    replace_turkish_characters( CHANGING cv_text = rv_result ).
    remove_non_alphanum_chars( CHANGING cv_text = rv_result ).

    IF iv_no_space = abap_true.
      REPLACE ALL OCCURRENCES OF ` ` IN rv_result WITH '_'.
    ENDIF.
  ENDMETHOD.


  METHOD remove_text_in_string.
    rv_result = iv_string.
    REPLACE ALL OCCURRENCES OF iv_remove IN rv_result WITH space.
  ENDMETHOD.


  METHOD replace_turkish_characters.
    REPLACE ALL OCCURRENCES OF:
      'ı' IN cv_text WITH 'i',
      'ğ' IN cv_text WITH 'g',
      'Ğ' IN cv_text WITH 'G',
      'ü' IN cv_text WITH 'u',
      'Ü' IN cv_text WITH 'U',
      'ş' IN cv_text WITH 's',
      'Ş' IN cv_text WITH 'S',
      'İ' IN cv_text WITH 'I',
      'ö' IN cv_text WITH 'o',
      'Ö' IN cv_text WITH 'O',
      'ç' IN cv_text WITH 'c',
      'Ç' IN cv_text WITH 'C'.
  ENDMETHOD.


  METHOD replace_turkish_chars_in_itab.
    FIELD-SYMBOLS <lt_itab> TYPE ANY TABLE.

    ASSERT ir_itab   IS NOT INITIAL AND
           it_fields IS NOT INITIAL.

    ASSIGN ir_itab->* TO <lt_itab>.

    LOOP AT <lt_itab> ASSIGNING FIELD-SYMBOL(<ls_itab>).
      LOOP AT it_fields ASSIGNING FIELD-SYMBOL(<lv_fieldname>).
        ASSIGN COMPONENT <lv_fieldname> OF STRUCTURE <ls_itab> TO FIELD-SYMBOL(<lv_field>).
        ASSERT sy-subrc EQ 0.
        replace_turkish_characters( CHANGING cv_text = <lv_field> ).
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD upper_case.
    rv_output = iv_input.
    TRANSLATE rv_output TO UPPER CASE.
  ENDMETHOD.

ENDCLASS.