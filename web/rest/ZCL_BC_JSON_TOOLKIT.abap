CLASS zcl_bc_json_toolkit DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS:
      is_initial
        IMPORTING !iv_json_value    TYPE clike
        RETURNING VALUE(rv_initial) TYPE abap_bool,

      is_null
        IMPORTING !iv_json_value TYPE clike
        RETURNING VALUE(rv_null) TYPE abap_bool,

      get_json_date
        IMPORTING !iv_timestamp  TYPE clike
        RETURNING VALUE(rv_date) TYPE dats,

      get_json_text
        IMPORTING !iv_val        TYPE any
        RETURNING VALUE(rv_text) TYPE string,

      get_json_text_from_amount
        IMPORTING !iv_val        TYPE any
        RETURNING VALUE(rv_text) TYPE string,

      get_json_text_from_bool
        IMPORTING !iv_val        TYPE abap_bool
        RETURNING VALUE(rv_text) TYPE string,

      get_json_text_from_numc
        IMPORTING !iv_val        TYPE any
        RETURNING VALUE(rv_text) TYPE string,

      get_json_text_from_quan
        IMPORTING !iv_val        TYPE any
        RETURNING VALUE(rv_text) TYPE string,

      get_json_text_from_round_quan
        IMPORTING !iv_val        TYPE any
        RETURNING VALUE(rv_text) TYPE string,

      get_json_time
        IMPORTING !iv_timestamp  TYPE clike
        RETURNING VALUE(rv_time) TYPE tims,

      parse_json_bool
        IMPORTING !iv_bool       TYPE clike
        RETURNING VALUE(rv_bool) TYPE abap_bool,

      parse_json_timestamp
        IMPORTING
          !iv_timestamp TYPE clike
        EXPORTING
          !ev_date      TYPE dats
          !ev_time      TYPE tims,

      restore_turkish_characters CHANGING !cv_json_string TYPE clike,

      sap_datetime_to_json_timestamp
        IMPORTING
          !iv_date            TYPE dats
          !iv_time            TYPE tims OPTIONAL
        RETURNING
          VALUE(rv_timestamp) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS:
      c_json_null_max TYPE text4 VALUE 'NULL',
      c_json_null_min TYPE text4 VALUE 'null'.

ENDCLASS.



CLASS ZCL_BC_JSON_TOOLKIT IMPLEMENTATION.


  METHOD get_json_date.
    parse_json_timestamp( EXPORTING iv_timestamp = iv_timestamp
                          IMPORTING ev_date      = rv_date ).
  ENDMETHOD.


  METHOD get_json_text.
    DATA lv_text TYPE text255.
    WRITE iv_val TO lv_text LEFT-JUSTIFIED.
    rv_text = lv_text.

    REPLACE ALL OCCURRENCES OF:
        '\' IN rv_text WITH '\\',
        '"' IN rv_text WITH '\"'.
  ENDMETHOD.


  METHOD get_json_text_from_amount.
    rv_text = get_json_text_from_quan( iv_val ).
  ENDMETHOD.


  METHOD get_json_text_from_bool.
    rv_text = SWITCH #( iv_val WHEN abap_true THEN 'true' ELSE 'false' ).
  ENDMETHOD.


  METHOD get_json_text_from_numc.
    rv_text = iv_val.
    SHIFT rv_text LEFT DELETING LEADING '0'.
  ENDMETHOD.


  METHOD get_json_text_from_quan.
    DATA lv_text TYPE text100.
    WRITE iv_val TO lv_text LEFT-JUSTIFIED.
    REPLACE ALL OCCURRENCES OF: '.' IN lv_text WITH space,
                                ',' IN lv_text WITH '.'.
    rv_text = lv_text.
  ENDMETHOD.


  METHOD get_json_text_from_round_quan.
    DATA quan_as_text TYPE text100.
    DATA(rounded_quan) = trunc( round( val = iv_val
                                       dec = 0 ) ).
    WRITE rounded_quan TO quan_as_text LEFT-JUSTIFIED.
    rv_text = quan_as_text.
    "--------->> add by mehmet sertkaya 27.11.2020 15:09:09
    REPLACE ALL OCCURRENCES OF '.' IN rv_text WITH ''.
    "-----------------------------<<
  ENDMETHOD.


  METHOD get_json_time.
    parse_json_timestamp( EXPORTING iv_timestamp = iv_timestamp
                          IMPORTING ev_time      = rv_time ).
  ENDMETHOD.


  METHOD is_initial.
    rv_initial = xsdbool(
        iv_json_value IS INITIAL OR
        is_null( iv_json_value ) EQ abap_true ).
  ENDMETHOD.


  METHOD is_null.
    rv_null = xsdbool(
        iv_json_value EQ c_json_null_max OR
        iv_json_value EQ c_json_null_min ).
  ENDMETHOD.


  METHOD parse_json_bool.
    rv_bool = boolc( iv_bool EQ 'true' OR iv_bool EQ 'TRUE' ).
  ENDMETHOD.


  METHOD parse_json_timestamp.

    "2016-05-12T16:55:55.023+0300

    CLEAR: ev_date, ev_time.

    IF is_initial( iv_timestamp ).
      RETURN.
    ENDIF.

    ev_date = |{ iv_timestamp+0(4) }{ iv_timestamp+5(2) }{ iv_timestamp+8(2) }|.

    IF ev_time IS REQUESTED AND strlen( iv_timestamp ) GT 10.
      ev_time = |{ iv_timestamp+11(2) }{ iv_timestamp+14(2) }{ iv_timestamp+17(2) }|.
    ENDIF.

  ENDMETHOD.


  METHOD restore_turkish_characters.
    REPLACE ALL OCCURRENCES OF:
        's\u0327' IN cv_json_string WITH 'ş',
        'g\u0306' IN cv_json_string WITH 'ğ',

        '\u00fc'  IN cv_json_string WITH 'ü',
        '\u011f'  IN cv_json_string WITH 'ğ',
        '\u0131'  IN cv_json_string WITH 'ı',
        '\u015f'  IN cv_json_string WITH 'ş',
        '\u00e7'  IN cv_json_string WITH 'ç',
        '\u00f6'  IN cv_json_string WITH 'ö',
        '\u00dc'  IN cv_json_string WITH 'Ü',
        '\u011e'  IN cv_json_string WITH 'Ğ',
        '\u0130'  IN cv_json_string WITH 'İ',
        '\u015e'  IN cv_json_string WITH 'Ş',
        '\u00c7'  IN cv_json_string WITH 'Ç',
        '\u00d6'  IN cv_json_string WITH 'Ö',
        '\u00a0'  IN cv_json_string WITH ' '.
  ENDMETHOD.


  METHOD sap_datetime_to_json_timestamp.
    rv_timestamp = |{ iv_date+0(4) }-{ iv_date+4(2) }-{ iv_date+6(2) }T{ iv_time+0(2) }:{ iv_time+2(2) }:{ iv_time+4(2) }.000+0000|.
  ENDMETHOD.
ENDCLASS.