CLASS zcl_mm_purchase_order DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.

    TYPES: BEGIN OF t_header,
             ernam TYPE ekko-ernam,
             bstyp TYPE ekko-bstyp,
             bsart TYPE ekko-bsart,
           END OF t_header,

           BEGIN OF t_key,
             ebeln TYPE ebeln,
           END OF t_key.

    CONSTANTS: BEGIN OF c_procstat,
                 approved         TYPE ekko-procstat VALUE '05',
                 waiting_approval TYPE ekko-procstat VALUE '03',
               END OF c_procstat.

    DATA: gs_header TYPE t_header,
          gv_ebeln  TYPE ebeln READ-ONLY.

    CLASS-METHODS:
      get_creator
        IMPORTING !iv_ebeln       TYPE ebeln
        RETURNING VALUE(rv_ernam) TYPE ekko-ernam
        RAISING   zcx_bc_table_content,

      get_instance
        IMPORTING !is_key       TYPE t_key
        RETURNING VALUE(ro_obj) TYPE REF TO zcl_mm_purchase_order
        RAISING   cx_no_entry_in_table.

    METHODS:
      cancel_old_active_workflows.

  PROTECTED SECTION.

  PRIVATE SECTION.

    TYPES: BEGIN OF t_multiton,
             key TYPE t_key,
             obj TYPE REF TO zcl_mm_purchase_order,
             cx  TYPE REF TO cx_no_entry_in_table,
           END OF t_multiton,

           tt_multiton TYPE HASHED TABLE OF t_multiton WITH UNIQUE KEY primary_key COMPONENTS key.

    CONSTANTS: BEGIN OF c_catid,
                 business_object TYPE sww_wi2obj-catid VALUE 'BO',
               END OF c_catid,

               BEGIN OF c_field,
                 creator TYPE fieldname VALUE 'ERNAM',
               END OF c_field,

               BEGIN OF c_tabname,
                 def TYPE tabname VALUE 'EKKO',
               END OF c_tabname,

               BEGIN OF c_typeid,
                 purchase_order TYPE sww_wi2obj-typeid VALUE 'BUS2012',
               END OF c_typeid.

    CLASS-DATA gt_multiton TYPE tt_multiton.

    METHODS:
      constructor
        IMPORTING !is_key TYPE t_key
        RAISING   cx_no_entry_in_table.

ENDCLASS.


CLASS zcl_mm_purchase_order IMPLEMENTATION.

  METHOD cancel_old_active_workflows.

    zcl_bc_wf_toolkit=>cancel_old_active_workflows(
        iv_catid  = c_catid-business_object
        iv_instid = CONV #( gv_ebeln )
        iv_typeid = c_typeid-purchase_order ).

  ENDMETHOD.


  METHOD constructor.
    gv_ebeln = is_key-ebeln.

    SELECT SINGLE ernam, bstyp, bsart FROM ekko
           WHERE ebeln = @gv_ebeln
           INTO CORRESPONDING FIELDS OF @gs_header.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_no_entry_in_table
        EXPORTING
          table_name = CONV #( c_tabname-def )
          entry_name = |{ gv_ebeln }|.
    ENDIF.
  ENDMETHOD.


  METHOD get_creator.
    TRY.
        rv_ernam = zcl_mm_purchase_order=>get_instance( VALUE #( ebeln = iv_ebeln ) )->gs_header-ernam.
      CATCH cx_no_entry_in_table INTO DATA(lo_neit).
        RAISE EXCEPTION TYPE zcx_bc_table_content
          EXPORTING
            textid   = zcx_bc_table_content=>entry_missing
            previous = lo_neit
            objectid = CONV #( iv_ebeln )
            tabname  = c_tabname-def.
    ENDTRY.

    IF rv_ernam IS INITIAL. " Paranoya
      RAISE EXCEPTION TYPE zcx_bc_table_content
        EXPORTING
          textid    = zcx_bc_table_content=>entry_field_initial
          objectid  = CONV #( iv_ebeln )
          tabname   = c_tabname-def
          fieldname = c_field-creator.
    ENDIF.
  ENDMETHOD.


  METHOD get_instance.

    ASSIGN gt_multiton[ KEY primary_key COMPONENTS key = is_key
                      ] TO FIELD-SYMBOL(<ls_multiton>).

    IF sy-subrc <> 0.
      DATA(ls_multiton) = VALUE t_multiton( key = is_key ).

      TRY.
          ls_multiton-obj = NEW #( ls_multiton-key ).
        CATCH cx_no_entry_in_table INTO ls_multiton-cx ##NO_HANDLER.
      ENDTRY.

      INSERT ls_multiton INTO TABLE gt_multiton ASSIGNING <ls_multiton>.
    ENDIF.

    IF <ls_multiton>-cx IS NOT INITIAL.
      RAISE EXCEPTION <ls_multiton>-cx.
    ENDIF.

    ro_obj = <ls_multiton>-obj.
  ENDMETHOD.

ENDCLASS.
