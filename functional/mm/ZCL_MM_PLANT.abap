CLASS zcl_mm_plant DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.

    CONSTANTS c_tabname_def TYPE tabname VALUE 'T001W'.

    DATA gs_def TYPE t001w READ-ONLY.

    CLASS-METHODS:
      get_instance
        IMPORTING !iv_werks       TYPE werks_d
        RETURNING VALUE(ro_plant) TYPE REF TO zcl_mm_plant
        RAISING   zcx_mm_plant_def,

      get_name_safe
        IMPORTING !iv_werks       TYPE werks_d
        RETURNING VALUE(rv_name1) TYPE name1.

    METHODS get_company_code RETURNING VALUE(rv_bukrs) TYPE bukrs.

    METHODS get_stlocs RETURNING VALUE(result) TYPE dfps_lgort_t.

    METHODS get_open_period RETURNING VALUE(result) TYPE zi_mm_open_plant_period.

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES:
      BEGIN OF t_lazy_flg,
        bukrs       TYPE abap_bool,
        stlocs      TYPE abap_bool,
        open_period TYPE abap_bool,
      END OF t_lazy_flg,

      BEGIN OF t_lazy_val,
        bukrs       TYPE bukrs,
        stlocs      TYPE dfps_lgort_t,
        open_period TYPE zi_mm_open_plant_period,
      END OF t_lazy_val,

      BEGIN OF t_lazy,
        flg TYPE t_lazy_flg,
        val TYPE t_lazy_val,
      END OF t_lazy,

      BEGIN OF t_mtt,
        werks TYPE werks_d,
        obj   TYPE REF TO zcl_mm_plant,
      END OF t_mtt,

      tt_mtt
        TYPE HASHED TABLE OF t_mtt
        WITH UNIQUE KEY primary_key COMPONENTS werks.

    CLASS-DATA gt_mtt TYPE tt_mtt.

    DATA gs_lazy TYPE t_lazy.

ENDCLASS.



CLASS zcl_mm_plant IMPLEMENTATION.


  METHOD get_company_code.
    IF gs_lazy-flg-bukrs IS INITIAL.
      SELECT SINGLE bukrs INTO @gs_lazy-val-bukrs FROM t001k WHERE bwkey EQ @gs_def-werks.
      gs_lazy-flg-bukrs = abap_true.
    ENDIF.

    rv_bukrs = gs_lazy-val-bukrs.
  ENDMETHOD.


  METHOD get_stlocs.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Lazy okuma ile depo yerlerini döndürür
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    IF gs_lazy-flg-stlocs IS INITIAL.
      SELECT lgort FROM t001l WHERE werks = @gs_def-werks INTO TABLE @gs_lazy-val-stlocs.
      gs_lazy-flg-stlocs = abap_true.
    ENDIF.

    result = gs_lazy-val-stlocs.
  ENDMETHOD.


  METHOD get_open_period.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Lazy okuma ile açık dönemi döndürür
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    IF gs_lazy-flg-open_period IS INITIAL.
      SELECT SINGLE * FROM zi_mm_open_plant_period
             WHERE werks = @me->gs_def-werks
             INTO @gs_lazy-val-open_period.

      gs_lazy-flg-open_period = abap_true.
    ENDIF.

    result = gs_lazy-val-open_period.
  ENDMETHOD.


  METHOD get_instance.

    ASSIGN gt_mtt[
      KEY primary_key
      COMPONENTS werks = iv_werks
    ] TO FIELD-SYMBOL(<ls_mtt>).

    IF sy-subrc NE 0.

      DATA(ls_mtt) = VALUE t_mtt( werks = iv_werks ).
      ls_mtt-obj = NEW #( ).

      SELECT SINGLE * INTO @ls_mtt-obj->gs_def
        FROM t001w
        WHERE werks EQ @ls_mtt-werks.

      IF sy-subrc NE 0.

        RAISE EXCEPTION TYPE zcx_mm_plant_def
          EXPORTING
            werks    = ls_mtt-werks
            previous = NEW zcx_bc_table_content(
              textid   = zcx_bc_table_content=>entry_missing
              objectid = CONV #( ls_mtt-werks )
              tabname  = c_tabname_def
            ).

      ENDIF.

      INSERT ls_mtt INTO TABLE gt_mtt ASSIGNING <ls_mtt>.

    ENDIF.

    ro_plant = <ls_mtt>-obj.

  ENDMETHOD.

  METHOD get_name_safe.

    TRY.
        rv_name1 = get_instance( iv_werks )->gs_def-name1.
      CATCH cx_root ##no_handler .
    ENDTRY.

  ENDMETHOD.

ENDCLASS.