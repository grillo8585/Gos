class ZCL_PP_BOM definition
  public
  final
  create public .

public section.

  types:
    tt_prdha TYPE RANGE OF mara-prdha .
  types:
    tt_stktx TYPE RANGE OF stko-stktx .

  data GT_HEADER type ZPPTT_BOM_HEADER .
  data GS_HEADER type ZPPS_BOM_HEADER .
  data GT_STB type ZPPTT_STPOX .
  data GT_MATCAT type ZPPTT_CSCMAT .

  methods READ_DATA
    importing
      !IM_MEHRS type MEHRS optional
      !IM_CAPID type CAPID default 'PP01'
      !IM_BMENG type BMENG optional
      !IM_DATUV type DATUV optional
      !IT_WERKS type /LIME/R_WERKS optional
      !IT_MATNR type /BEV2/ED_RG_T_MATNR optional
      !IT_STLAL type CURTO_STLAL_RANGE_T optional
      !IT_STLAN type CURTO_STLAL_RANGE_T optional
      !IT_PRDHA type TT_PRDHA optional
      !IT_STKTX type TT_STKTX optional
      !IV_ELIMINATE_OLD_DATUV type ABAP_BOOL default ABAP_FALSE
    returning
      value(ET_DATA) type ZPPTT_BOM_DATA .
  methods READ_BOM
    importing
      !IM_WERKS type WERKS_D
      !IM_MATNR type MATNR
      !IM_STLAL type STLAL optional
      !IM_STLAN type STLAN
      !IM_CAPID type CAPID default 'PP01'
      !IM_BMENG type BMENG optional
      !IM_DATUV type DATUV default SY-DATUM
      !IM_MEHRS type MEHRS default SPACE
    exporting
      !ES_TOPMAT type CSTMAT
    changing
      !ET_MATCAT type ZPPTT_CSCMAT optional
    returning
      value(ET_STB) type ZPPTT_STPOX .
  PROTECTED SECTION.

  PRIVATE SECTION.

    METHODS read_header
      IMPORTING
        !it_werks               TYPE /lime/r_werks OPTIONAL
        !it_matnr               TYPE /bev2/ed_rg_t_matnr OPTIONAL
        !it_stlal               TYPE curto_stlal_range_t OPTIONAL
        !it_stlan               TYPE curto_stlal_range_t OPTIONAL
        !it_prdha               TYPE tt_prdha OPTIONAL
        !it_stktx               TYPE tt_stktx OPTIONAL
        !iv_datuv               TYPE stko-datuv OPTIONAL
        !iv_eliminate_old_datuv TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(et_header)        TYPE zpptt_bom_header .

ENDCLASS.



CLASS ZCL_PP_BOM IMPLEMENTATION.


  METHOD read_bom.

    CLEAR: es_topmat, et_stb, et_matcat.

    CALL FUNCTION 'CS_BOM_EXPL_MAT_V2' ##FM_SUBRC_OK
      EXPORTING
*       FTREL                 = ' '
*       ALEKZ                 = ' '
*       ALTVO                 = ' '
*       AUFSW                 = ' '
*       AUMGB                 = ' '
*       AUMNG                 = 0
*       AUSKZ                 = ' '
*       AMIND                 = ' '
*       BAGRP                 = ' '
*       BEIKZ                 = ' '
*       BESSL                 = ' '
*       BGIXO                 = ' '
*       BREMS                 = ' '
        capid                 = im_capid
*       CHLST                 = ' '
*       COSPR                 = ' '
*       CUOBJ                 = 000000000000000
*       CUOVS                 = 0
*       CUOLS                 = ' '
        datuv                 = im_datuv
*       DELNL                 = ' '
*       DRLDT                 = ' '
        ehndl                 = '1'
        emeng                 = im_bmeng
*       ERSKZ                 = ' '
*       ERSSL                 = ' '
*       FBSTP                 = ' '
*       KNFBA                 = ' '
*       KSBVO                 = ' '
*       MBWLS                 = ' '
        mktls                 = 'X'
*       MDMPS                 = ' '
        mehrs                 = im_mehrs
*       MKMAT                 = ' '
*       MMAPS                 = ' '
*       SALWW                 = ' '
*       SPLWW                 = ' '
        mmory                 = '1'
        mtnrv                 = im_matnr
*       NLINK                 = ' '
*       POSTP                 = ' '
*       RNDKZ                 = ' '
*       RVREL                 = ' '
*       SANFR                 = ' '
*       SANIN                 = ' '
*       SANKA                 = ' '
*       SANKO                 = ' '
*       SANVS                 = ' '
*       SCHGT                 = ' '
*       STKKZ                 = ' '
        stlal                 = im_stlal
        stlan                 = im_stlan
*       STPST                 = 0
        svwvo                 = 'X'
        werks                 = im_werks
*       NORVL                 = ' '
*       MDNOT                 = ' '
*       PANOT                 = ' '
*       QVERW                 = ' '
*       VERID                 = ' '
        vrsvo                 = 'X'
      IMPORTING
        topmat                = es_topmat
*       DSTST                 =
      TABLES
        stb                   = et_stb
        matcat                = et_matcat
      EXCEPTIONS
        alt_not_found         = 1
        call_invalid          = 2
        material_not_found    = 3
        missing_authorization = 4
        no_bom_found          = 5
        no_plant_data         = 6
        no_suitable_bom_found = 7
        conversion_error      = 8
        OTHERS                = 9.
    gt_stb[]    = et_stb[].
    gt_matcat[] = et_matcat[].

  ENDMETHOD.


  METHOD read_data.

    DATA:
      lt_stb  TYPE TABLE OF stpox,
      ls_stb  TYPE stpox,
      lv_mod  TYPE i,
      lv_top  TYPE i,
      lv_len  TYPE i VALUE 100,
      ls_data LIKE LINE OF et_data.

* init
    REFRESH et_data.

* başlık bilgileri

    read_header(
      it_werks = it_werks
      it_matnr = it_matnr
      it_stlal = it_stlal
      it_stlan = it_stlan
      it_prdha = it_prdha
      it_stktx = it_stktx
      iv_datuv = im_datuv
      iv_eliminate_old_datuv = iv_eliminate_old_datuv
    ).

    LOOP AT gt_header INTO gs_header.

*   bilgilendirme mesajı
      lv_mod = sy-tabix MOD lv_len.
      IF lv_mod = 0.
        zcl_bc_gui_toolkit=>sapgui_mess( iv_top  =  lv_top
                                         iv_akt  =  sy-tabix
                                         iv_len  =  lv_len
                                         iv_text =  TEXT-001  ).

      ENDIF.

      CLEAR ls_data.
*   başlık verileri
      MOVE-CORRESPONDING gs_header TO ls_data.

*   ürün ağacı bileşenler
      REFRESH lt_stb.

      lt_stb[] = read_bom( im_werks = ls_data-werks
                           im_matnr = ls_data-matnr
                           im_stlal = ls_data-stlal
                           im_stlan = ls_data-stlan
                           im_capid = im_capid
                           im_bmeng = im_bmeng
                           im_datuv = im_datuv
                           im_mehrs = im_mehrs ).

      IF lt_stb[] IS NOT INITIAL.

        TRY.
            zcl_mm_material=>cache_maktx(
              ir_tab  = REF #( lt_stb )
              iv_fnam = 'IDNRK'
            ).
          CATCH cx_root ##no_handler .
        ENDTRY.

        LOOP AT lt_stb INTO ls_stb.
          MOVE-CORRESPONDING ls_stb TO ls_data ##ENH_OK.
          ls_data-imaktx = zcl_mm_material=>get_maktx( ls_data-idnrk ).
          APPEND ls_data TO et_data.
        ENDLOOP.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD read_header.

    DATA:
      lt_mara    TYPE SORTED TABLE OF mara WITH UNIQUE KEY matnr,
      lv_date    TYPE csap_mbom-datuv,
      "--------->> add by mehmet sertkaya 16.04.2021 11:47:01
      lv_matnr40 TYPE csap_mbom-matnr.
    "-----------------------------<<

    FIELD-SYMBOLS <fs_header> TYPE zpps_bom_header .

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Verileri çek
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    REFRESH et_header.

    SELECT  stko~* , mast~matnr , mast~stlan , mast~werks
           INTO CORRESPONDING FIELDS OF TABLE @et_header ##TOO_MANY_ITAB_FIELDS
           FROM mast
           INNER JOIN stko
           ON mast~stlnr EQ stko~stlnr AND
              mast~stlal EQ stko~stlal
           WHERE
                 mast~werks IN @it_werks AND
                 mast~matnr IN @it_matnr AND
                 mast~stlal IN @it_stlal AND
                 mast~stlan IN @it_stlan AND
                 stko~stlty EQ 'M' AND
                 stko~lkenz EQ @space AND
                 stko~loekz EQ @space AND
                 stko~datuv LE @iv_datuv AND
                 stko~stktx IN @it_stktx.

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " İstendiyse, sadece en güncel verinin kalacağı şekilde filtreleme yap
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    IF iv_eliminate_old_datuv EQ abap_true.

      SORT et_header BY
        stlty ASCENDING
        stlnr ASCENDING
        stlal ASCENDING
        datuv DESCENDING.

      DELETE ADJACENT DUPLICATES FROM et_header COMPARING stlty stlnr stlal.

    ENDIF.

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Ana verileri tamamla ve ek filtreleri uygula
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    TRY.
        zcl_mm_material=>cache_maktx( REF #( et_header ) ).
      CATCH cx_root ##no_handler .
    ENDTRY.

    LOOP AT et_header ASSIGNING <fs_header>.

      <fs_header>-maktx = zcl_mm_material=>get_maktx( <fs_header>-matnr ).

      TRY.
          <fs_header>-prdha = lt_mara[ KEY primary_key
                               matnr = <fs_header>-matnr ]-prdha.
        CATCH cx_sy_itab_line_not_found ##NO_HANDLER.
      ENDTRY.

      IF <fs_header>-prdha NOT IN it_prdha.
        DELETE et_header.
      ENDIF.

      WRITE iv_datuv TO lv_date.

      lv_matnr40 = <fs_header>-matnr.

      CALL FUNCTION 'CSAP_MAT_BOM_READ'
        EXPORTING
*          material    = <fs_header>-matnr
          material    = lv_matnr40
          plant       = <fs_header>-werks
          bom_usage   = <fs_header>-stlan
          alternative = <fs_header>-stlal
          valid_from  = lv_date
          valid_to    = lv_date
        EXCEPTIONS
          error       = 1
          OTHERS      = 2.

      IF sy-subrc <> 0.
        DELETE et_header.
      ENDIF.

    ENDLOOP.

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Dönüş
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    gt_header[] = et_header[].

  ENDMETHOD.
ENDCLASS.