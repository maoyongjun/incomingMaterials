CREATE OR REPLACE PROCEDURE MES1.check_material_vendor_sp(res       OUT VARCHAR2,
                                                          i_tr_sn   IN VARCHAR2,
                                                          i_machine IN VARCHAR2) IS

  v_count             INT;
  v_hhpn              VARCHAR2(100);
  V_last_vendorpartno VARCHAR2(100);
  V_vendorpartno      VARCHAR2(100);
  v_last_propertity   VARCHAR2(100);
  v_propertity        VARCHAR2(100);
  v_smt_code          VARCHAR2(100);
  v_replace_hhpn      VARCHAR2(100);
  v_last_replace_hhpn VARCHAR2(100);
  v_work_time         R_TR_CODE_DETAIL.Work_Time%TYPE;
--�w�q��СA������N��
  CURSOR c_kp_no IS
    SELECT KP_NO, REPLACE_KP_NO
      FROM C_REPLACE_KP
     WHERE SMT_CODE = v_smt_code
       AND (KP_NO = v_hhpn OR REPLACE_KP_NO = v_hhpn);
  c_row c_kp_no%rowtype;
  
BEGIN
  BEGIN
    SELECT CUST_KP_NO, mfr_kp_no
      INTO v_hhpn, V_vendorpartno
      FROM R_TR_SN
     WHERE TR_SN = i_tr_sn;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20000,
                              'ERROR:can find record,tr_sn:' || i_tr_sn);
  END;

  DBMS_OUTPUT.put_line('0:v_hhpn-->' || v_hhpn || ',V_vendorpartno-->' ||
                       V_vendorpartno);

  SELECT COUNT(1)
    INTO v_count
    FROM MES1.c_material_vendor_config
   WHERE hhpn = v_hhpn;

  DBMS_OUTPUT.put_line('v_hhpn-->' || v_hhpn ||
                       ',MES1.c_material_vendor_config count-->' ||
                       v_count);

  --HHPN�O�ݩʪ�O�_�s�b
  IF v_count > 0 THEN
  
    SELECT COUNT(1)
      INTO v_count
      FROM R_TR_CODE_DETAIL
     WHERE KP_NO = v_hhpn
       AND STATION = i_machine
       AND ROWNUM<10;
  
    --�ˬd�W�ưO���O�_�s�b
    IF v_count > 0 THEN
    
      SELECT MFR_KP_NO
        INTO V_last_vendorpartno
        FROM (SELECT MFR_KP_NO
                FROM R_TR_CODE_DETAIL
               WHERE KP_NO = v_hhpn
                 AND STATION = i_machine
               order by WORK_TIME desc)
       WHERE ROWNUM = 1;
    
      DBMS_OUTPUT.put_line('1Y2Y:V_last_vendorpartno-->' ||
                           V_last_vendorpartno || ',V_vendorpartno:' ||
                           V_vendorpartno);
      IF V_vendorpartno = V_last_vendorpartno THEN
        res := 'OK'; --��^���G
      ELSE
      
        BEGIN
          SELECT propertity
            INTO v_last_propertity
            FROM MES1.c_material_vendor_config
           WHERE VENDOR_PARTNO = V_last_vendorpartno
             and hhpn = v_hhpn
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_last_propertity := '';
        END;
      
        DBMS_OUTPUT.put_line('1Y2Y3N:v_last_propertity-->' ||
                             v_last_propertity);
        --�����ӮƸ��b�ݩʪ�O�_�s�b
        IF v_last_propertity IS NOT NULL THEN
        
          BEGIN
            SELECT propertity
              INTO v_propertity
              FROM MES1.c_material_vendor_config
             WHERE hhpn = v_hhpn
               and propertity = v_last_propertity
               and vendor_partno = V_vendorpartno
               and rownum = 1;--�q�L�ݩʩM�E���Ƹ��d��O���A�����ӥi�H���P
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_propertity := '';
          END;
        
          DBMS_OUTPUT.put_line('1Y2Y3N4Y:v_hhpn-->' || v_hhpn);
          --�ݩʬO�_�۵�
          IF v_propertity IS NOT NULL THEN
            res := 'OK';
          ELSE
            res := 'ERROR:InComing Polarity,Please call EE'; --��^���G
          END IF;
        
        ELSE
          res := 'WARNING:First online ,please call EE'; --��^���G
        END IF;
      END IF;
    
    ELSE
    
      BEGIN
        SELECT SMT_CODE
          INTO v_smt_code
          FROM (SELECT SMT_CODE
                  FROM MES4.R_STATION_WIP
                 WHERE STATION = i_machine
                 ORDER BY WORK_TIME DESC)
         WHERE ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20000, 'ERROR:SMT CODE IS NULL');
      END;
     v_work_time:=TO_DATE('1990-1-1 00:00:00', 'YYYY-MM-DD HH24:MI:SS');
     --�ާ@�̪񪺴��N�ưO��
      FOR c_row IN c_kp_no LOOP
        DBMS_OUTPUT.put_line('1Y2N-->' || c_row.KP_NO || ':' ||
                             c_row.REPLACE_KP_NO);
      
        v_replace_hhpn := c_row.KP_NO;
      
        IF v_replace_hhpn <> v_hhpn THEN
        
          SELECT count(1)
            INTO V_count
            FROM R_TR_CODE_DETAIL
           WHERE KP_NO = v_replace_hhpn
             AND STATION = i_machine
             AND WORK_TIME > v_work_time;
          IF V_count > 0 THEN
            --�d��̪񪺤@���O��
            SELECT WORK_TIME, MFR_KP_NO, KP_NO
              INTO v_work_time, V_last_vendorpartno, v_last_replace_hhpn
              FROM (SELECT WORK_TIME, MFR_KP_NO, KP_NO
                      FROM R_TR_CODE_DETAIL
                     WHERE KP_NO = v_replace_hhpn
                       AND STATION = i_machine
                       AND WORK_TIME > v_work_time
                     order by WORK_TIME desc)
             WHERE ROWNUM = 1;
          END IF;
        
        END IF;
      
        v_replace_hhpn := c_row.REPLACE_KP_NO;
      
        IF v_replace_hhpn <> v_hhpn THEN
        
          SELECT count(1)
            INTO V_count
            FROM R_TR_CODE_DETAIL
           WHERE KP_NO = v_replace_hhpn
             AND STATION = i_machine
             AND WORK_TIME > v_work_time;
        
          IF V_count > 0 THEN
          
            --�d��̪񪺤@���O��
            SELECT WORK_TIME, MFR_KP_NO, KP_NO
              INTO v_work_time, V_last_vendorpartno, v_last_replace_hhpn
              FROM (SELECT WORK_TIME, MFR_KP_NO, KP_NO
                      FROM R_TR_CODE_DETAIL
                     WHERE KP_NO = v_replace_hhpn
                       AND STATION = i_machine
                       AND WORK_TIME > v_work_time
                     order by WORK_TIME desc)
             WHERE ROWNUM = 1;
          END IF;
        END IF;
      
      END LOOP;
    
      --�p�G�����N�ƪ��O���A����̪񪺱��y�O���������ӮƸ�
      IF v_work_time > TO_DATE('1990-1-1 00:00:00', 'YYYY-MM-DD HH24:MI:SS') THEN
      
        SELECT count(1)
          INTO v_count
          FROM MES1.c_material_vendor_config
         WHERE hhpn = v_last_replace_hhpn;
      
        --�b�ݩʪ�O�_�s�b
        IF v_count > 0 THEN
        
          SELECT COUNT(1)
            INTO v_count
            FROM MES1.c_material_vendor_config a,
                 MES1.c_material_vendor_config b
           WHERE a.hhpn = v_hhpn
             and b.hhpn = v_last_replace_hhpn
             and a.propertity = b.propertity;
        
          IF v_count > 0 THEN
            res := 'OK'; --��^ 
          ELSE
            res := 'ERROR:Incoming Polarity Different ,Please Call EE!';--��^ 
          END IF;
        ELSE
          res := 'WARNING:First on line ,Please Call EE!HHPN:' || v_hhpn; --��^
        END IF;
      
      ELSE
        res := 'WARNING:First on line ,Please Call EE!HHPN:' || v_hhpn; --��^
      END IF;
    END IF;
  
  ELSE
  
    BEGIN
      SELECT SMT_CODE
        INTO v_smt_code
        FROM (SELECT SMT_CODE
                FROM MES4.R_STATION_WIP
               WHERE STATION = i_machine
               ORDER BY WORK_TIME DESC)
       WHERE ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_smt_code := '';
    END;
  
    DBMS_OUTPUT.put_line('1N-->v_smt_code:' || v_smt_code);
  
    --�d����x�����N�ƪ��E���Ƹ�
    FOR c_row IN c_kp_no LOOP
      DBMS_OUTPUT.put_line('1N-->' || c_row.KP_NO || ':' ||
                           c_row.REPLACE_KP_NO);
    
      v_replace_hhpn := c_row.KP_NO;
    
      IF v_replace_hhpn <> v_hhpn THEN
        BEGIN
          SELECT v_replace_hhpn || ':' || VENDOR_PARTNO
            INTO V_last_vendorpartno
            FROM MES1.c_material_vendor_config
           WHERE hhpn = v_replace_hhpn
             and rownum = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            V_last_vendorpartno := '';
        END;
        IF V_last_vendorpartno IS NOT NULL THEN
          EXIT;
        END IF;
        
      END IF;
    
      v_replace_hhpn := c_row.REPLACE_KP_NO;
    
      IF v_replace_hhpn <> v_hhpn THEN
      
        BEGIN
          SELECT v_replace_hhpn || ':' || VENDOR_PARTNO
            INTO V_last_vendorpartno
            FROM MES1.c_material_vendor_config
           WHERE hhpn = v_replace_hhpn
             and rownum = 1;
        
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            V_last_vendorpartno := '';
        END;
        IF V_last_vendorpartno IS NOT NULL THEN
          EXIT;
        END IF;
      
      END IF;
    
    END LOOP;
  
    --���N�Ʀb�ݩʪ�s�b
    IF V_last_vendorpartno IS not null THEN
      res := 'First on line ,Please Call EE!HHPN:'||v_hhpn ; --��^ 
    ELSE
      res := 'OK'; --��^ 
    END IF;
  
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    res := res || ',' || SQLERRM(SQLCODE);
END;
/
