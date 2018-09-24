CREATE OR REPLACE PACKAGE EFD_SPED_FPROC IS


	-- Public type declarations
	Mlayout Cad_Reg_Layout.Cod_Layout%TYPE;
	ProcID integer := 0;
	FUNCTION Parametros RETURN VARCHAR2;
	FUNCTION Nome RETURN VARCHAR2;
	FUNCTION Tipo RETURN VARCHAR2;
 FUNCTION gera_linha_final_arquivo RETURN VARCHAR2;
	FUNCTION Versao RETURN VARCHAR2;
	FUNCTION Descricao RETURN VARCHAR2;
	FUNCTION Modulo RETURN VARCHAR2;
	FUNCTION Classificacao RETURN VARCHAR2;
	FUNCTION Orientacao RETURN VARCHAR2;
	FUNCTION Executar(
							Pdataini         DATE,
							Pdatafim         DATE,
       Pleiaute         VARCHAR2,
							Pperfil          VARCHAR2,
							Pfinalidade      VARCHAR2,
              Pdatainv         DATE,
              PdataSldLpd      DATE,
              PqtdMaxlog       Varchar2 DEFAULT '0',
							Pindcentr        VARCHAR2,
              pMultEmp         VARCHAR2,
              pUf              VARCHAR2,
							Pcod_Estab       VARCHAR2) RETURN INTEGER;
	PROCEDURE Teste;
	PROCEDURE TesteEfd05;

	PRAGMA RESTRICT_REFERENCES(Nome, WNDS);
	PRAGMA RESTRICT_REFERENCES(Parametros, WNDS);

END EFD_SPED_FPROC;
/
CREATE OR REPLACE PACKAGE BODY EFD_SPED_FPROC IS

	Mcod_Empresa Empresa.Cod_Empresa%TYPE;
  Mcod_Estab   Estabelecimento.Cod_Estab%TYPE;
  Mcod_Usuario usuario_empresa.cod_usuario%TYPE;

	-- Private type declarations
	FUNCTION Parametros RETURN VARCHAR2 IS
		Pstr VARCHAR2(5000);
	BEGIN
		--A implementar:
		--formatação dos parametros será:
		--Titulo|Tipo da Variavel|Mandatorio|Dafault|Select;
		--Decrição
		--Titulo..........: Caption a ser mostrado na tela
		--Tipo da Variavel: Conforme definido no Oracle
		--Tipo de Controle: Textbox, Listbox, Combobox, Radiobutton ou Checkbox
		--Mandatorio......: S ou N
		--Dafault.........: Valor Default para o Campo
		--Máscara.........: dd/mm/yyyy
		--Valores.........: Comando SQL para a lista (Código, Descrição)

		Mcod_Empresa := Lib_Parametros.Recuperar('EMPRESA');
    Mcod_Usuario := LIB_PARAMETROS.RECUPERAR('USUARIO');


		-- :1
		Lib_Proc.Add_Param(Pstr,
								 'Data Inicial',
								 'Date',
								 'Textbox',
								 'N',
								 NULL,
								 'DD/MM/YYYY');

		-- :2
		Lib_Proc.Add_Param(Pstr,
								 'Data Final',
								 'Date',
								 'Textbox',
								 'N',
								 NULL,
								 'DD/MM/YYYY');

		-- :3
		Lib_Proc.Add_Param(Pstr,
								 'Leiaute',
								 'Varchar2',
								 'Combobox',
								 'S',
								 NULL,
								 '',
								 'SELECT LAY.COD_LAYOUT, LAY.COD_LAYOUT || '' - '' || LAY.DSC_LAYOUT FROM CAD_LAYOUT LAY WHERE COD_LAYOUT in (''EFD101'',''EFD102'',''EFD103'',''EFD104'',''EFD105'',''EFD106'',''EFD107'',''EFD108'',''EFD109'',''EFD110'',''EFD111'') ORDER BY COD_LAYOUT');


		-- :4
		Lib_Proc.Add_Param(Pstr,
								 'Perfil',
								 'Varchar2',
								 'Combobox',
								 'S',
								 NULL,
								 '',
								 'SELECT PERFIL.COD_PERFIL, PERFIL.COD_PERFIL || '' - '' || PERFIL.DSC_PERFIL FROM COTEPE_PERFIL PERFIL WHERE COD_LAYOUT = :3');

		-- :5
		Lib_Proc.Add_Param(Pstr,
								 'Finalidade',
								 'Varchar2',
								 'ListBox',
								 'N',
								 '00',
								 NULL,
								 '00=Remessa do Arquivo Original,' ||
								 '01=Remessa do Arquivo Substituto');

   	-- :6
		Lib_Proc.Add_Param(Pstr,
								 'Data do Inventario',
								 'Date',
								 'Textbox',
								 'N',
								 NULL,
								 'DD/MM/YYYY');

   	-- :7
		Lib_Proc.Add_Param(Pstr,
								 'Data Saldo Inicial LPD(Cotepe 41)',
								 'Date',
								 'Textbox',
								 'N',
								 NULL,
								 'DD/MM/YYYY');

   	-- :8
		Lib_Proc.Add_Param(Pstr,
								 'Qtd. Max. de logs (0 = todos)',
								 'Varchar2',
								 'Textbox',
								 'N',
								 '0',
								 '####');

   	-- :9
	  Lib_Proc.Add_Param(Pstr, 'Geracao p/Inscricao Estadual Unica',
				         'Varchar2',
				         'Radiobutton',
				         'S',
				         'N',
				         Pvalores => 'S=Sim,N=Nao');

    -- :10
    lib_proc.add_param(pstr,
                     'Geracao Multiempresa',
                     'Varchar2',
                     'Checkbox',
                     'N',
								     'N',
                      NULL);


     -- :11
     LIB_PROC.add_param(pstr,
                       'UF',
                       'Varchar2',
                       'Combobox',
                       'N',
                       '%',
                       NULL,
                       'SELECT cod_estado, descricao FROM estado UNION SELECT ''%'', ''* Todas as UFs *'' FROM dual ORDER BY cod_estado',
                       'N');



		-- :12
	  Lib_Proc.Add_Param(Pstr,
								 'Estabelecimento',
								 'Varchar2',
								 'MultiProc',
								 'S',
								 '',
								 '',
                 'SELECT a.cod_estab, ' ||
								 '       a.cod_estab||'' - ''||a.razao_social ' ||
								 '  FROM estabelecimento a, EFD_PERFIL_ESTAB_V B, ESTADO D ' || ' WHERE a.cod_empresa = ''' ||
								 Mcod_Empresa || '''' ||
                 ' AND A.COD_EMPRESA=B.COD_EMPRESA AND A.COD_ESTAB=B.COD_ESTAB' ||
                 ' AND a.ident_estado = d.ident_estado AND d.cod_estado like :11'||
                 ' AND B.COD_LAYOUT=:3 AND B.COD_PERFIL=:4' ||
                 ' AND :9 = ''N''' ||
                 ' AND :10 = ''N''' ||
								 'UNION ALL SELECT a.cod_estab, ' ||
								 '       a.cod_estab||'' - ''||a.razao_social ' ||
								 '  FROM estabelecimento a, EFD_PERFIL_ESTAB_V B, ESTADO D ' || ' WHERE a.cod_empresa = ''' ||
								 Mcod_Empresa || '''' ||
                 ' AND A.COD_EMPRESA=B.COD_EMPRESA AND A.COD_ESTAB=B.COD_ESTAB' ||
                 ' AND a.ident_estado = d.ident_estado AND d.cod_estado like :11'||
                 ' AND B.COD_LAYOUT=:3 AND B.COD_PERFIL=:4' ||
                 ' AND :9 = ''S'' AND EXISTS (SELECT 1 FROM ICP_INSC_EST_CENTR b WHERE b.cod_empresa = a.cod_empresa and b.cod_estab_centr=a.cod_estab) ' ||
                 ' AND :10 = ''N''' ||
                 'UNION ALL SELECT a.cod_empresa||''#''||a.cod_estab Cod_Emp#Cod_Estab, ' ||
								 '       c.cod_empresa||'' - ''||substr(c.razao_social,1,30) ||'' / ''|| a.cod_estab||'' - ''||a.razao_social ' ||
								 '  FROM estabelecimento a, EFD_PERFIL_ESTAB_V B, EMPRESA C, ESTADO D ' || ' WHERE A.COD_EMPRESA=B.COD_EMPRESA AND A.COD_ESTAB=B.COD_ESTAB' ||
                 ' AND A.COD_EMPRESA=C.COD_EMPRESA ' ||
                 ' AND a.ident_estado = d.ident_estado AND d.cod_estado like :11'||
                 ' AND B.COD_LAYOUT=:3 AND B.COD_PERFIL=:4' ||
                 ' AND  EXISTS (SELECT usuario_empresa.cod_empresa ' ||
                         '                FROM   usuario_empresa  ' ||
                        '                 WHERE  (usuario_empresa.cod_empresa = a.COD_EMPRESA)  ' ||
                        '                 AND    (usuario_empresa.cod_usuario = ''' || mcod_usuario || '''))   ' ||
                 ' AND :9 = ''N''' ||
                 ' AND :10 = ''S''' ||
                 'UNION ALL SELECT a.cod_empresa||''#''||a.cod_estab Cod_Emp#Cod_Estab, ' ||
								 '       c.cod_empresa||'' - ''||substr(c.razao_social,1,30) ||'' / ''|| a.cod_estab||'' - ''||a.razao_social ' ||
								 '  FROM estabelecimento a, EFD_PERFIL_ESTAB_V B, EMPRESA C, ESTADO D ' || ' WHERE A.COD_EMPRESA=B.COD_EMPRESA AND A.COD_ESTAB=B.COD_ESTAB' ||
                 ' AND A.COD_EMPRESA=C.COD_EMPRESA ' ||
                 ' AND a.ident_estado = d.ident_estado AND d.cod_estado like :11'||
                 ' AND B.COD_LAYOUT=:3 AND B.COD_PERFIL=:4' ||
                 ' AND :9 = ''S'' AND EXISTS (SELECT 1 FROM ICP_INSC_EST_CENTR b WHERE b.cod_empresa = a.cod_empresa and b.cod_estab_centr=a.cod_estab) ' ||
                 ' AND  EXISTS (SELECT usuario_empresa.cod_empresa ' ||
                         '                FROM   usuario_empresa  ' ||
                        '                 WHERE  (usuario_empresa.cod_empresa = a.COD_EMPRESA)  ' ||
                        '                 AND    (usuario_empresa.cod_usuario = ''' || mcod_usuario || '''))   ' ||
                 ' AND :10 = ''S''' ||

         ' ORDER BY 1');


		RETURN Pstr;
	END;

	FUNCTION Nome RETURN VARCHAR2 IS
	BEGIN
		-- Nome da janela
		RETURN 'Geracao do Meio Magnetico - EFD';
	END Nome;

	FUNCTION Tipo RETURN VARCHAR2 IS
	BEGIN
		RETURN 'Geracao de Arquivo Magnetico';
	END Tipo;

 -- Esta função indica ao framework que será adicionada
 -- uma linha em branco ao final de cada arquivo gerado
 -- Esta solução foi implementada em função de uma falha
 -- no validador, que não enxergava a última linha
 -- do arquivo por causa da falta do carrige return/line feed
 FUNCTION gera_linha_final_arquivo RETURN VARCHAR2 IS
 BEGIN
 RETURN 'S';
 END;

	FUNCTION Versao RETURN VARCHAR2 IS
	BEGIN
		RETURN '1.0';
	END;

	FUNCTION Descricao RETURN VARCHAR2 IS
	BEGIN
		RETURN 'Geracao dos Arquivos - EFD';
	END;

	FUNCTION Modulo RETURN VARCHAR2 IS
	BEGIN
		RETURN 'SPED - EFD';
	END;

	FUNCTION Classificacao RETURN VARCHAR2 IS
	BEGIN
		RETURN 'Atendimento Legal';
	END;

	FUNCTION Orientacao RETURN VARCHAR2 IS
	BEGIN
		-- Orientação do Papel
		RETURN 'LANDSCAPE';
	END;

PROCEDURE Rel_Conferencia(pCod_Perfil       VARCHAR2,
								  Pleiaute         VARCHAR2,
								  Pdataini         DATE,
								  Pdatafim         DATE,
								  Pfinalidade      VARCHAR2,
								  Pcod_Estab       VARCHAR2) IS
	-- DECLARE
	i                INTEGER;
	Quant_Campos     INTEGER := 0;
	Teste            VARCHAR2(20);
	Linha_w          VARCHAR2(200) := '';
	Linha_Reg_w      VARCHAR2(200) := '';
	Indice           INTEGER;
	Alinhamento      VARCHAR2(1) := 'D';
	Tamanho_Pai      INTEGER;
	Valor_w          VARCHAR2(20);
	Decimais         INTEGER;
	Gerou            BOOLEAN := FALSE;
	Cod_Reg_Ant      VARCHAR2(10) := '0000';
	Dif              INTEGER := 0;
	Linha_Atual      INTEGER := 0;

	TYPE Rlayout IS RECORD(
		Campo       INTEGER,
		Tamanho     INTEGER,
		Maximo      INTEGER,
		Alinhamento VARCHAR2(1),
		Totalizacao NUMBER);
	TYPE Tlayout IS TABLE OF Rlayout INDEX BY BINARY_INTEGER;
	Vlayout Tlayout;


	TYPE Rinirel IS RECORD(
		Leiaute         VARCHAR2(255),
		Perfil          VARCHAR2(255),
		Data_Ini        VARCHAR2(255),
		Data_Fim        VARCHAR2(255),
		Tp_Invent       VARCHAR2(255),
		Finalidade      VARCHAR2(255),
		Insc_Unica      VARCHAR2(255),
		Estabelecimento VARCHAR2(255),
		Empresa         VARCHAR2(255));

	Vinirel Rinirel;

	PROCEDURE Desc_Registro(p_Reg_Atual    IN VARCHAR2, -- C1.COD_REGISTRO
									p_Reg_Anterior IN VARCHAR2, --cod_reg_ant
									p_Dsc_Registro IN OUT VARCHAR2) IS
		--C1.Dsc_Registro
		p_Tamanho VARCHAR2(200);
	BEGIN

		IF p_Reg_Atual <> p_Reg_Anterior THEN
			IF Substr(p_Reg_Atual, 2, 1) <> Substr(p_Reg_Anterior, 2, 1) THEN
				Lib_Proc.Add(' ', Ptipo => 2);
			END IF;
			IF Lib_Proc.Get_Currentrow(2) >= 40 THEN
				Lib_Proc.New_Page(2);
			END IF;

			Lib_Proc.Add('|' || Lpad('-', 148, '-') || '|', Ptipo => 2);
			IF p_Reg_Atual = '9900' THEN
				p_Dsc_Registro := 'Total de Registros do Arquivo';
			END IF;

			p_Tamanho := Abs((148 - (Length(p_Dsc_Registro || ' (' || p_Reg_Atual || ')') + 2)) / 2);
			Lib_Proc.Add('|' ||
							 Lpad(Lpad(' ', p_Tamanho, ' ') || ' ' || p_Dsc_Registro || ' (' || p_Reg_Atual || ')' || ' ' || Lpad(' ', p_Tamanho, ' '),
									148,
									' ') || '|',
							 Ptipo => 2);
			Lib_Proc.Add('|' || Lpad('-', 148, '-') || '|', Ptipo => 2);
			IF p_Reg_Atual NOT IN ('E360', '9900') THEN
				Lib_Proc.Add(Substr(Rpad(Linha_Reg_w, 149, ' '), 1, 149) || '|', Ptipo => 2);
				Lib_Proc.Add('|' || Lpad('-', 148, '-') || '|', Ptipo => 2);
			END IF;
			Linha_Reg_w := '';
		END IF;

	END;

BEGIN
	-- Define relatorio e arquivo destinos
	Lib_Arqmag_Util.Seta_Destino(2, 2);


   Vinirel.Leiaute := '';
   Vinirel.Perfil  := '';
   Vinirel.Data_Ini  := '';
   Vinirel.Data_Fim  := '';
   Vinirel.Tp_Invent  := '';
   Vinirel.Finalidade  := '';
   Vinirel.Insc_Unica   := '';
   Vinirel.Estabelecimento  := '';
   Vinirel.Empresa          := '';


	SELECT Razao_Social INTO Vinirel.Empresa FROM Empresa WHERE Cod_Empresa = Mcod_Empresa;

	SELECT Razao_Social
	  INTO Vinirel.Estabelecimento
	  FROM Estabelecimento
	 WHERE Cod_Empresa = Mcod_Empresa
		AND Cod_Estab = Pcod_Estab;

	SELECT Dsc_Perfil
	  INTO Vinirel.Perfil
	  FROM Cotepe_Perfil
	 WHERE Cod_Layout = Pleiaute
		AND Cod_Perfil = pCod_Perfil;

	IF Pfinalidade = '00' THEN
		Vinirel.Finalidade := 'Remessa regular de arquivo';
	ELSIF Pfinalidade = '01' THEN
		Vinirel.Finalidade := 'Remessa de arquivo substituto';
	ELSIF Pfinalidade = '02' THEN
		Vinirel.Finalidade := 'Remessa de arquivo com dados adicionais a arquivo anteriormente remetido';
	ELSIF Pfinalidade = '03' THEN
		Vinirel.Finalidade := 'Remessa de arquivo requerido por intimação específica';
	ELSIF Pfinalidade = '04' THEN
		Vinirel.Finalidade := 'Remessa de arquivo requerido para correção do Índice de Participação dos Municípios';
	ELSIF Pfinalidade = '05' THEN
		Vinirel.Finalidade := 'Remessa de arquivo requerido por ato publicado no Diário Oficial';
	ELSIF Pfinalidade = '15' THEN
		Vinirel.Finalidade := 'Sintegra - remessa regular de arquivo das operações interestaduais';
	ELSIF Pfinalidade = '16' THEN
		Vinirel.Finalidade := 'Sintegra - remessa de arquivo substituto das operações interestaduais';
	ELSIF Pfinalidade = '17' THEN
		Vinirel.Finalidade := 'Sintegra - remessa de arquivo com dados adicionais das operações interestaduais';
	ELSIF Pfinalidade = '18' THEN
		Vinirel.Finalidade := 'Sintegra - remessa regular de arquivo das operações interestaduais com substituição tributária do ICM';
	ELSIF Pfinalidade = '19' THEN
		Vinirel.Finalidade := 'Sintegra - remessa de arquivo substituto das operações interestaduais com substituição tributária do ICM';
	ELSIF Pfinalidade = '20' THEN
		Vinirel.Finalidade := 'Sintegra -remessa de arquivo com dados adicionais das operações interestaduais com substituição tributária do ICM';
	ELSIF Pfinalidade = '25' THEN
		Vinirel.Finalidade := 'Remessa para a Sefin-Mun de arquivo de retenções do ISSQN efetuadas por terceiros';
	ELSIF Pfinalidade = '26' THEN
		Vinirel.Finalidade := 'Remessa para a Sefin-Mun de arquivo substituto de retenções do ISSQN efetuadas por terceiros';
	ELSIF Pfinalidade = '27' THEN
		Vinirel.Finalidade := 'Remessa para a Sefin-Mun de arquivo com dados adicionais de retenções do ISSQN efetuadas por terceiros';
	ELSIF Pfinalidade = '30' THEN
		Vinirel.Finalidade := 'Emissão de documento';
	ELSIF Pfinalidade = '31' THEN
		Vinirel.Finalidade := 'Emissão de documento fiscal avulso por repartição fiscal';
	ELSIF Pfinalidade = '61' THEN
		Vinirel.Finalidade := 'Solicitação de Auditor-Fiscal da Secretaria da Receita Previdenciária através de MPF';
	ELSIF Pfinalidade = '62' THEN
		Vinirel.Finalidade := 'Entrega na Secretaria da Receita Previdenciária -movimento anual de órgão público conforme intimação';
	ELSIF Pfinalidade = '90' THEN
		Vinirel.Finalidade := 'Remessa de informações complementares para a Sefaz da unidade da federação de origem';
	END IF;

	SELECT Dsc_Layout INTO Vinirel.Leiaute FROM Cad_Layout WHERE Cod_Layout = Pleiaute;

	Lib_Proc.Add(Rpad('|--', 149, '-') || '|', Ptipo => 2);
	Lib_Proc.Add(Rpad('| EMPRESA:         ' || Vinirel.Empresa, 117, ' ') || 'Período: ' || Pdataini || ' a ' || Pdatafim || '|', Ptipo => 2);
	Lib_Proc.Add(Rpad('| ESTABELECIMENTO: ' || Vinirel.Estabelecimento, 149, ' ') || '|', Ptipo => 2);
	Lib_Proc.Add(Rpad('| PROCESSO: ' || Procid, 97, ' ') || Rpad('Perfil: ' || Substr(pCod_Perfil || ' - ' || Vinirel.Perfil, 1, 40), 52) || '|',
					 Ptipo => 2);
	Lib_Proc.Add(Rpad('| Leiaute: ' || Vinirel.Leiaute, 97, ' ') || Rpad('Finalidade: ' || Substr(Vinirel.Finalidade, 1, 40), 52) || '|', Ptipo => 2);
	Lib_Proc.Add(Rpad('| Relatório para Conferência do Meio Magnético (Ato Cotepe nº011/07) ', 149, ' ') || '|', Ptipo => 2);
	Lib_Proc.Add('|' || Lpad('-', 148, '-') || '|', Ptipo => 2);
	-- REGISTROS À SEREM GERADOS

	Vlayout.DELETE;
  lib_proc.gravarLinhasLibProcSaida;

	FOR C1 IN
     (SELECT DISTINCT a.Texto, b.Cod_Layout, b.Cod_Bloco, b.Cod_Registro, a.Chave_Ordenacao, c.Nivel_Hierarq, d.Tamanho, c.Dsc_Registro
					 FROM Lib_Proc_Saida a,
							Cotepe_Det_Perfil b,
							Cad_Reg_Layout c,
							(SELECT t.Cod_Layout, t.Cod_Bloco, t.Cod_Registro, SUM(Greatest(Length(t.Nome_Campo), t.Tamanho)) Tamanho
								FROM Det_Reg_Layout t
							  WHERE t.Pos_Chave IS NOT NULL
								 AND t.Cod_Registro IN ('C100')
							  GROUP BY t.Cod_Layout, t.Cod_Bloco, t.Cod_Registro) d
					WHERE a.Proc_Id = Procid
					  AND b.Cod_Layout = Mlayout
					  AND b.Cod_Perfil = pCod_Perfil
					  AND c.Cod_Layout = b.Cod_Layout
					  AND c.Cod_Bloco = b.Cod_Bloco
					  AND c.Cod_Registro = b.Cod_Registro
					  AND d.Cod_Layout = c.Cod_Layout
					  AND d.Cod_Bloco = c.Cod_Bloco
					  AND d.Cod_Registro = c.Cod_Registro
					  AND b.Cod_Bloco = Substr(a.Chave_Ordenacao, 4, 1)
					  AND b.Cod_Registro = Substr(a.Texto, 2, 4)
					ORDER BY 5, 3, 4) LOOP

		-- Define as colunas do registro
		FOR C3 IN (SELECT t.Posicao, t.Nome_Campo, t.Pos_Chave, t.Dsc_Campo, t.Tipo, Nvl(t.Tamanho, 20) Tamanho, b.Nivel_Hierarq
						 FROM Det_Reg_Layout t, Cad_Reg_Layout b
						WHERE t.Cod_Layout = C1.Cod_Layout
						  AND t.Cod_Bloco = C1.Cod_Bloco
						  AND t.Cod_Registro = C1.Cod_Registro
						  AND b.Cod_Layout = t.Cod_Layout
						  AND b.Cod_Bloco = t.Cod_Bloco
						  AND b.Cod_Registro = t.Cod_Registro
						  AND t.Posicao <> '1'
						ORDER BY t.Cod_Bloco, t.Cod_Registro, t.Posicao) LOOP

			Quant_Campos := Quant_Campos + 1;
			Vlayout(Substr(C1.Cod_Registro, 2, 3) || Quant_Campos).Campo := Quant_Campos;

			-- A variável DIF é utilizada para diminuir a distância entre as colunas de cada registro
			-- Caso um registro não caiba dentro do relatório é possível diminuir o espaçamento entre as colunas
/*			IF C1.Cod_Registro = 'B470' THEN
				Dif := 16;
			ELSIF C1.Cod_Registro IN ('E360', '9900') THEN
				Dif := -108;
			ELSIF C1.Cod_Registro IN ('B430') THEN
				Dif := 6;
			ELSE
				Dif := 3;
			END IF;
*/
			Tamanho_Pai := Greatest(Length(C3.Nome_Campo), C3.Tamanho - Dif);
			Vlayout(Substr(C1.Cod_Registro, 2, 3) || Quant_Campos).Tamanho := Tamanho_Pai;

/*			IF C1.Cod_Registro IN ('E360', '9900') THEN
				IF NOT Gerou THEN
					Desc_Registro(C1.Cod_Registro, Cod_Reg_Ant, C1.Dsc_Registro);
					Gerou := TRUE;
				END IF;

				IF C1.Cod_Registro = 'E360' THEN
					Linha_Reg_w := Substr('|' || Rpad(C3.Dsc_Campo, Tamanho_Pai, ' '), 1, 127);
					Linha_Reg_w := Substr(Linha_Reg_w || '|' ||
												 Lpad(Nvl(Substr(C1.Texto,
																	  (Instr(C1.Texto, '|', 1, C3.Posicao)) + 1,
																	  (Instr(C1.Texto, '|', 1, C3.Posicao + 1)) - ((Instr(C1.Texto, '|', 1, C3.Posicao)) + 1)),
															 ' '),
														20,
														' '),
												 1,
												 148);

					Lib_Proc.Add(Substr(Rpad(Linha_Reg_w, 149, ' '), 1, 149) || '|', Ptipo => 2);
					Linha_Reg_w := '';
				ELSE
					IF C3.Posicao = 2 THEN
						Linha_Reg_w := Lpad('| Total de registros ' ||
												  Nvl(Substr(C1.Texto,
																 (Instr(C1.Texto, '|', 1, C3.Posicao)) + 1,
																 (Instr(C1.Texto, '|', 1, C3.Posicao + 1)) - ((Instr(C1.Texto, '|', 1, C3.Posicao)) + 1)),
														' ') || ' : ',
												  28,
												  ' ');
					ELSE
						Linha_Reg_w := Linha_Reg_w || ' ' ||
											Substr(Lpad(Nvl(Substr(C1.Texto,
																		  (Instr(C1.Texto, '|', 1, C3.Posicao)) + 1,
																		  (Instr(C1.Texto, '|', 1, C3.Posicao + 1)) - ((Instr(C1.Texto, '|', 1, C3.Posicao)) + 1)),
																 '0'),
															5,
															'0'),
													 1,
													 148);
						Lib_Proc.Add(Substr(Rpad(Linha_Reg_w, 149, ' '), 1, 149) || '|', Ptipo => 2);
						Linha_Reg_w := '';
					END IF;
				END IF;

			ELSE*/
				Linha_Reg_w := Substr(Linha_Reg_w || '|' || Lpad(C3.Nome_Campo, Tamanho_Pai, ' '), 1, 148);
--			END IF;

		END LOOP;
		Gerou        := FALSE;

		IF Substr(C1.Cod_Registro, 2, 1) <> Substr(Cod_Reg_Ant, 2, 1) AND C1.Cod_Registro NOT IN ('E360', '9900') THEN
			Lib_Proc.Add(' ', Ptipo => 2);
			Lib_Proc.Add(' ', Ptipo => 2);
			Lib_Proc.Add('|' || Lpad('=', 148, '=') || '|', Ptipo => 2);
			IF Substr(C1.Cod_Registro, 2, 1) = '4' THEN
				Lib_Proc.Add('|' || Lpad(' ', 68, ' ') || ' RESUMO ISS ' || Lpad(' ', 68, ' ') || '|', Ptipo => 2);
			ELSIF Substr(C1.Cod_Registro, 2, 1) = '3' THEN
				Lib_Proc.Add('|' || Lpad(' ', 68, ' ') || ' RESUMO ICMS ' || Lpad(' ', 67, ' ') || '|', Ptipo => 2);
			ELSIF Substr(C1.Cod_Registro, 2, 1) = '5' THEN
				Lib_Proc.Add('|' || Lpad(' ', 68, ' ') || ' RESUMO IPI ' || Lpad(' ', 68, ' ') || '|', Ptipo => 2);
			END IF;
			Lib_Proc.Add('|' || Lpad('=', 148, '=') || '|', Ptipo => 2);
		END IF;

		IF C1.Cod_Registro NOT IN ('E360', '9900') THEN
			Desc_Registro(C1.Cod_Registro, Cod_Reg_Ant, C1.Dsc_Registro);
		END IF;

		FOR i IN 1 .. Vlayout.COUNT LOOP
			IF Vlayout.EXISTS(Substr(C1.Cod_Registro, 2, 3) || i) AND C1.Cod_Registro NOT IN ('E360', '9900') THEN
				Indice := Substr(C1.Cod_Registro, 2, 3) || i;
				-- Lib_Proc.Add(Indice, Ptipo => 2);
				IF Vlayout(Indice).Campo = i THEN
					Linha_w := Substr(Linha_w || '|' || Lpad(Nvl(Substr(C1.Texto,
																						 (Instr(C1.Texto, '|', 1, i + 1)) + 1,
																						 (Instr(C1.Texto, '|', 1, i + 2)) - ((Instr(C1.Texto, '|', 1, i + 1)) + 1)),
																				' '),
																		  Vlayout(Indice).Tamanho,
																		  ' '),
											1,
											148);

				END IF;
				Indice := Vlayout.NEXT(Indice);
			END IF;
		END LOOP;

		IF C1.Cod_Registro NOT IN ('E360', '9900') AND Length(Linha_w) > 5 THEN
			Lib_Proc.Add(Substr(Rpad(Linha_w, 149, ' '), 1, 149) || '|', Ptipo => 2);
		END IF;
		Linha_w     := '';
		Linha_Reg_w := '';
		Valor_w     := '';
		Decimais    := 0;

		Linha_Atual := Lib_Proc.Get_Currentrow(2);
		IF Lib_Proc.Get_Currentrow(2) >= 48 THEN
			--Lib_Proc.Add(' ', Ptipo => 2);
			Lib_Proc.New_Page(2);
		END IF;

		Teste := 15;

		Quant_Campos := 0;
		Cod_Reg_Ant  := C1.Cod_Registro;

		Teste := 16;
	END LOOP;
	Vlayout.DELETE;
	COMMIT;
EXCEPTION
	WHEN OTHERS THEN
		Lib_Proc.Add_Log(Teste || ' - Erro ao gerar o Relatório de conferência: ' || SQLERRM, 0);
		COMMIT;
END Rel_Conferencia;


	FUNCTION Executar(
							Pdataini         DATE,
							Pdatafim         DATE,
              Pleiaute         VARCHAR2,
							Pperfil          VARCHAR2,
							Pfinalidade      VARCHAR2,
              Pdatainv         DATE,
              PdataSldLpd      DATE,
              PqtdMaxlog       Varchar2 DEFAULT '0',
							Pindcentr        VARCHAR2,
              pMultEmp         VARCHAR2,
              pUf              VARCHAR2,
							Pcod_Estab       VARCHAR2) RETURN INTEGER IS

		Finalizar  EXCEPTION;
		Arquivo_w  varchar2(30);
		Status_w   integer;
		task_w     varchar2(100);
		v_sql      clob;
		v_exec     clob;
		l_offset   number := 1;
		NUM_THREAD integer;

	  cursor r_cursor is select * from EFD_ARQ_V;
		type t_linha is table of r_cursor%rowtype index by binary_integer;
    r_linha t_linha;
    Reg efd_layout.register;
    Sair exception;
    erro exception;
		
		cursor_c sys_refcursor;	
		type t_linha_EFD79 is table of efd79_dados_acumula_v%rowtype index by binary_integer;
		linha_EFD79	t_linha_EFD79;

		type lst_efd_capa is table of efd_capa_docfis%rowtype index by binary_integer;
		in_rec     lst_efd_capa;
		efd_capa_docfis_c sys_refcursor;
	  limit_bulk integer := 1000;

  mRazaoEmp       EMPRESA.RAZAO_SOCIAL%TYPE;
  mRazaoEst       ESTABELECIMENTO.RAZAO_SOCIAL%TYPE;
  mCGC            ESTABELECIMENTO.CGC%TYPE;
  mInd_Atividade  ESTABELECIMENTO.Ind_Atividade%type;
  mIndConvIcms    ESTABELECIMENTO.IND_CONV_ICMS%TYPE;
  mCodAtividade   ESTABELECIMENTO.COD_ATIVIDADE%TYPE;
  mUF_estab       ESTADO.COD_ESTADO%TYPE;
  mMunic_estab    MUNICIPIO.COD_MUNICIPIO%TYPE;
  mUfMunic_estab  MUNICIPIO.COD_UF%TYPE;
  linha_log       varchar2(100);
  qtdMaxlog       number:=0;

	BEGIN
    Mcod_Empresa := substr(Pcod_Estab,1,instr(Pcod_Estab,'#')-1);
    Mcod_Estab   := substr(Pcod_Estab,instr(Pcod_Estab,'#')+1);

    If Mcod_Empresa is null then
       Mcod_Empresa := Lib_Parametros.Recuperar('EMPRESA');
       Arquivo_w := Mcod_Estab || '_' || to_char(Pdataini, 'MM') || '_' ||to_char(Pdataini, 'YYYY')|| '_' || 'EFD.TXT';
    Else
       Lib_Parametros.Salvar('EMPRESA', Mcod_Empresa);
       Arquivo_w := Mcod_Empresa|| '_' ||Mcod_Estab || '_' || to_char(Pdataini, 'MM') || '_' ||to_char(Pdataini, 'YYYY')|| '_' || 'EFD.TXT';
    End If;

		Procid    := Lib_Proc.NEW(psp_nome=>'EFD_SPED_FPROC', pparticao=>'SPED_FISCAL');
		Lib_Proc.Add_Tipo(Procid, 1, Arquivo_w, 2);
		Lib_Proc.Add_Tipo(Procid, 2, 'Quantidade Total de Registros Gravados', 1, 48, 150, pfont_height => 11 );

--    Lib_Parametros.salvar('DATA_SLD_LPD',to_char(pdataSldLpd,'ddmmyyyy'));

  IF mcod_empresa IS NULL THEN
    lib_proc.Add_Log('Código da Empresa deve ser informado no login.', 0);
    lib_proc.Add_Log(' ', 0);
    lib_proc.CLOSE;
    RETURN Procid;
  END IF;

  -- Recupera informações da Empresa/Estabelecimento
  -- Que farão parte do cabeçalho do log de erros
  Begin
     Select a.razao_social, b.razao_social, b.cgc, b.ind_atividade, c.cod_estado, b.ind_conv_icms, b.cod_atividade, B.COD_MUNICIPIO, d.cod_uf
     Into   mRazaoEmp,      mRazaoEst,      mCGC,  mInd_Atividade,  mUF_estab, mIndConvIcms, mCodAtividade, mMunic_estab, mUfMunic_estab
     From Empresa a, Estabelecimento b, Estado c, Municipio d
     Where a.cod_empresa = b.cod_empresa
     And   a.cod_empresa = Mcod_Empresa
     And   b.cod_estab   = Mcod_Estab
     AND   c.ident_estado = b.ident_estado
     And   b.ident_estado = d.ident_estado (+)
     And   b.cod_municipio = d.cod_municipio (+);

  Exception
  When Others Then
    lib_proc.Add_Log('Ocorreu um erro durante a recuperação das informações de Empresa/Estabelecimento. Chave: '|| Mcod_Empresa || '-' || Mcod_Estab ||'. ' || sqlerrm, 0);
    lib_proc.Add_Log(' ', 0);
  End;

  -- Inclui Header/Footer do Log de Erros
  lib_proc.Add_Log(mRazaoemp, 0);
  lib_proc.Add_Log('Filial: ' || Mcod_Estab || ' - ' || mRazaoEst, 0);
  lib_proc.Add_Log('CNPJ: '   || mCGC, 0);
  lib_proc.Add_Log('.                                                                                                  Relatório de Log de Erros SPED', 0);
  lib_proc.Add_Log('.                                                                                               Dt.Ini : ' ||
                   to_date(Pdataini,'DD/MM/YYYY') || '  -  Dt.Fim: ' ||to_date(Pdatafim,'DD/MM/YYYY') , 0);

  linha_log := 'Log de Processo: '||Procid;
  lib_proc.Add_Log('.                                                                                                        '||linha_log, 0);


  lib_proc.Add_Log(rpad('-', 200, '-'), 0);
  lib_proc.Add_Log(' ', 0);

  -- Validação de datas inicial e final informadas
  If Pdataini > Pdatafim Then
     lib_proc.Add_Log('Data Inicial da geração deve ser menor que a Data Final.', 0);
     lib_proc.Add_Log(' ', 0);
     lib_proc.CLOSE;
     RETURN Procid;
  End If;

  EFD_Tab_Cadastro.Limpeza;
  efd_Layout.Ini_GerRegistro;
  efd_layout.Setlayout(Pleiaute, Pperfil, Pdataini, Pdatafim, Pindcentr);
  efd_layout.SetLayoutTab(ProcId, Pleiaute, pPerfil, pDataini, pDatafim);

  efd_Layout.Setmaxqtdlog(0, 'S');

  qtdMaxlog := to_number(PqtdMaxlog);
  IF qtdMaxlog  >0 THEN
     lib_proc.setMaxLog(qtdMaxlog);
  END IF;

  Mlayout := Pleiaute;

  IF pindcentr = 'S' THEN
     Efd_Layout.Setinscestunica;
     Efd_Dic_Dados.Setinscestunica;
  END IF;

  EFD_Tab_Cadastro.setProcId(ProcId);

  Status_w := EFD_Dados_Param.Setdadosgeracao(
                              Mcod_Empresa,
                              Mcod_Estab,
                              mInd_Atividade,
                              mUF_estab,
                              Pdataini,
                              Pdatafim,
                              Pdatainv,
                              Pfinalidade,
                              Procid,
                              Pleiaute,
                              Pperfil,
                              pindcentr,
                              mIndConvIcms,
                              mCodAtividade,
                              efd_layout.VerificaRegPerfil('EFD79'),
                              pDataSaldoIni => PdataSldLpd,
                              pMunicEstab => mMunic_estab,
                              pUfMunicEstab => mUfMunic_estab);

    IF Status_w = -1 THEN
     Lib_Proc.Add_Log('Erro ocorrido no processamento de informações iniciais da declaração (EFD_Dados_Param.setDadosGeracao). ' || sqlerrm,0);
        RAISE Finalizar;
    END IF;

    EXECUTE IMMEDIATE 'TRUNCATE TABLE EFD_ESTAB_TEMP';

    INSERT INTO EFD_ESTAB_TEMP (
      COD_EMPRESA,
      COD_ESTAB) (
      SELECT Mcod_Empresa,
             Mcod_Estab
        FROM DUAL
       WHERE Pindcentr = 'N'
      UNION ALL
      SELECT COD_EMPRESA,
             COD_ESTAB
        FROM ICP_INSC_EST_CENTR
       WHERE COD_EMPRESA = Mcod_Empresa
         AND COD_ESTAB_CENTR = Mcod_Estab
         AND Pindcentr = 'S');

    IF Pindcentr = 'S' THEN
       BEGIN
         SELECT 1 INTO Status_w
           FROM EFD_ESTAB_TEMP;
       EXCEPTION
         WHEN TOO_MANY_ROWS THEN
           Status_w := 1;
         WHEN NO_DATA_FOUND THEN
           Status_w := 0;
       END;
       IF Status_w = 0 THEN
          Lib_Proc.Add_Log('Não foram encontrados estabelecimentos controlados pelo estabelecimento controlador.',0);
          RAISE Finalizar;
       END IF;
    END IF;
		
  /*********************************************************/
  /*Chamada Genérica para Geração em paralelo dos Registros*/
  /*********************************************************/
  /*  BEGIN
       OPEN r_cursor;
       LOOP FETCH r_cursor
         BULK COLLECT INTO r_linha LIMIT limit_bulk;
         EXIT WHEN r_linha.COUNT = 0;
         FOR indx IN 1 .. r_linha.COUNT LOOP
           IF r_linha(indx).reg is not null and r_linha(indx).log is null and r_linha(indx).cad is null THEN
             Reg.Chave := r_linha(indx).chv_ordenacao;
             Reg.Registro := r_linha(indx).reg;
             If efd_layout.GravaReg(Reg) < 0 Then
               raise Sair;
             End If;
           END IF;
           IF r_linha(indx).log is not null THEN
             If efd_layout.GravaRegLog(r_linha(indx).log,r_linha(indx).log_nivel) < 0 Then
               raise Sair;
             End If;
           END IF;
           IF r_linha(indx).cad is not null THEN
             execute immediate r_linha(indx).cad using procid;
           END IF;
         END LOOP;
       END LOOP;
       CLOSE r_cursor;
       Efd_tab_cadastro.Close_TabCad;
       Efd_Layout.Close_TabRegistro;
    EXCEPTION
       When Sair Then CLOSE r_cursor;
       When Erro Then CLOSE r_cursor;
    END;

   \*Temporariamente, Efetua Carga Para EFD_CAPA_DOCFIS*\
    BEGIN
      Open efd_capa_docfis_c for Select VDO.* from EFD_CAPA_DOCFIS_VDO VDO;

      Loop
        Fetch efd_capa_docfis_c
        BULK COLLECT
        INTO in_rec
         LIMIT limit_bulk;

         EXIT WHEN in_rec.COUNT = 0;

         Forall i in 1 .. in_rec.count
                        merge into efd_capa_docfis t
                                   using ( select PROCID proc_id,
                                                  in_rec(i).cod_empresa cod_empresa,
                                                  in_rec(i).cod_estab cod_estab,
                                                  in_rec(i).data_fiscal data_fiscal,
                                                  in_rec(i).movto_e_s movto_e_s,
                                                  in_rec(i).norm_dev norm_dev,
                                                  in_rec(i).ident_docto ident_docto,
                                                  in_rec(i).ident_fis_jur ident_fis_jur,
                                                  in_rec(i).num_docfis num_docfis,
                                                  in_rec(i).serie_docfis serie_docfis,
                                                  in_rec(i).sub_serie_docfis sub_serie_docfis,
                                                  in_rec(i).data_saida_rec data_saida_rec,
                                                  in_rec(i).data_emissao data_emissao,
                                                  in_rec(i).dat_escr_extemp dat_escr_extemp,
                                                  in_rec(i).ind_oper ind_oper,
                                                  in_rec(i).ind_emit ind_emit,
                                                  in_rec(i).cod_part cod_part,
                                                  in_rec(i).cod_mod cod_mod,
                                                  in_rec(i).ind_pagto ind_pagto,
                                                  in_rec(i).cod_anp cod_anp,
                                                  in_rec(i).sit_escritura_especial sit_escritura_especial,
                                                  in_rec(i).cod_cfo cod_cfo,
                                                  in_rec(i).ident_fis_conces ident_fis_conces,
                                                  in_rec(i).ind_compra_venda ind_compra_venda,
                                                  in_rec(i).cod_uf_st cod_uf_st,
                                                  in_rec(i).sit_nfe_contribuinte sit_nfe_contribuinte,
                                                  in_rec(i).cod_estado_orig cod_estado_orig,
                                                  in_rec(i).cod_estado_dest cod_estado_dest,
                                                  in_rec(i).ident_fis_lsg ident_fis_lsg from dual ) d
                                      on (t.cod_empresa = d.cod_empresa and
                                          t.cod_estab = d.cod_estab and
                                          t.data_fiscal = d.data_fiscal and
                                          t.movto_e_s = d.movto_e_s and
                                          t.norm_dev = d.norm_dev and
                                          t.ident_docto = d.ident_docto and
                                          t.ident_fis_jur = d.ident_fis_jur and
                                          t.num_docfis = d.num_docfis and
                                          t.serie_docfis = d.serie_docfis and
                                          t.sub_serie_docfis = d.sub_serie_docfis)
                                    when not matched then insert values ( d.cod_empresa,
                                                                          d.cod_estab,
                                                                          d.data_fiscal,
                                                                          d.movto_e_s,
                                                                          d.norm_dev,
                                                                          d.ident_docto,
                                                                          d.ident_fis_jur,
                                                                          d.num_docfis,
                                                                          d.serie_docfis,
                                                                          d.sub_serie_docfis,
                                                                          d.data_saida_rec,
                                                                          d.data_emissao,
                                                                          d.dat_escr_extemp,
                                                                          d.ind_oper,
                                                                          d.ind_emit,
                                                                          d.cod_part,
                                                                          d.cod_mod,
                                                                          d.ind_pagto,
                                                                          d.cod_anp,
                                                                          d.sit_escritura_especial,
                                                                          d.cod_cfo,
                                                                          d.ident_fis_conces,
                                                                          d.ind_compra_venda,
                                                                          d.cod_uf_st,
                                                                          d.sit_nfe_contribuinte,
                                                                          d.cod_estado_orig,
                                                                          d.cod_estado_dest,
                                                                          d.ident_fis_lsg );
      End Loop;
      Close efd_capa_docfis_c;
    END;

   \*Temporariamente, Efetua as acumulações para o EFD79*\
	 If EFD_DADOS_PARAM.getIndGeraEFD79 Then
		 BEGIN
				 OPEN cursor_c for select * from efd79_dados_acumula_v;
				 LOOP FETCH cursor_c
					 BULK COLLECT INTO linha_EFD79 LIMIT limit_bulk;
					 EXIT WHEN linha_EFD79.COUNT = 0;
					 FOR indx IN 1 .. linha_EFD79.COUNT LOOP
						 If linha_EFD79(indx).IndCapaItem in ('ItemMerc','ItemServ') Then            
								Status_w := EFD79_DADOS.AcumulaOrigVA (linha_EFD79(indx).IndCapaItem,
																											 linha_EFD79(indx).Movto_e_s,
																											 linha_EFD79(indx).Situacao,
																											 linha_EFD79(indx).cfop,
																											 linha_EFD79(indx).Grupo_Natureza_Op,
																											 linha_EFD79(indx).Cod_Natureza_Op,
																											 linha_EFD79(indx).Cod_Mun_Orig,
																											 linha_EFD79(indx).Cod_Estado_Orig,
																											 Ltrim(Rtrim(linha_EFD79(indx).Grupo_Produto)),
																											 Ltrim(Rtrim(linha_EFD79(indx).Ind_Produto)),
																											 Ltrim(Rtrim(linha_EFD79(indx).Cod_Produto)),
																											 linha_EFD79(indx).Vl_Item,
																											 linha_EFD79(indx).COD_MOD,
																											 'D110',
																											 0,
																											 P_COD_CLASS_DOC_FIS => linha_EFD79(indx).Cod_Class_Doc_Fis);
							 IF Status_w = -1 THEN
									Lib_Proc.Add_Log('Erro ocorrido no processamento de informações iniciais da declaração (EFD79_DADOS.AcumulaOrigVA). ' || sqlerrm,0);
									RAISE Finalizar;
							 END IF;                           
	             
						 ElsIf linha_EFD79(indx).IndCapaItem = 'Capa' Then
							 Status_w := EFD79_DADOS.AcumulaOrigVA (linha_EFD79(indx).IndCapaItem,
																											linha_EFD79(indx).Movto_e_s,
																											linha_EFD79(indx).Situacao,
																											linha_EFD79(indx).cfop,
																											linha_EFD79(indx).Grupo_Natureza_Op,
																											linha_EFD79(indx).Cod_Natureza_Op,
																											linha_EFD79(indx).Cod_Mun_Orig,
																											linha_EFD79(indx).Cod_Estado_Orig,
																											Ltrim(Rtrim(linha_EFD79(indx).Grupo_Produto)),
																											Ltrim(Rtrim(linha_EFD79(indx).Ind_Produto)),
																											Ltrim(Rtrim(linha_EFD79(indx).Cod_Produto)),
																											linha_EFD79(indx).Vl_Doc,
																											linha_EFD79(indx).COD_MOD,
																											'D100',
																											0,
																											P_COD_CLASS_DOC_FIS => linha_EFD79(indx).Cod_Class_Doc_Fis);

							 IF Status_w = -1 THEN
									Lib_Proc.Add_Log('Erro ocorrido no processamento de informações iniciais da declaração (EFD79_DADOS.AcumulaOrigVA). ' || sqlerrm,0);
									RAISE Finalizar;
							 END IF;               
						 End If;                   
	         
					 END LOOP;
				 END LOOP;
				 CLOSE cursor_c;
			EXCEPTION
				 When Sair Then CLOSE cursor_c;
				 When Erro Then CLOSE cursor_c;
			END;
		End If;	*/     
   /*********************** Fim *****************************/				

    IF efd_layout.VerificaRegPerfil('EFD71') And EFD71_Gera.Periodlivro(Mcod_Empresa, Mcod_Estab) = -1 Then
        Raise Finalizar;
    End If;

-- EFD88 - Verifica Periodo para Geração da Sub-apuração - OS2931-F
    IF efd_layout.VerificaRegPerfil('EFD88') And EFD88_Gera.Periodlivro(Mcod_Empresa, Mcod_Estab) = -1 Then
        Raise Finalizar;
    End If;

    IF efd_layout.VerificaRegPerfil('EFD72') And EFD72_Gera.Periodlivro(Mcod_Empresa, Mcod_Estab) = -1 Then
        Raise Finalizar;
    End If;

    IF efd_layout.VerificaRegPerfil('EFD82') And EFD82_Gera.Periodlivro(Mcod_Empresa, Mcod_Estab) = -1 Then
        Raise Finalizar;
    End If;

-- EFD79 - Inicializa a tabela EFD_REG_1400 no início do processo
    IF efd_layout.VerificaRegPerfil('EFD79') Then
       IF EFD79_Gera.LimpaDadosReg1400 = -1 THEN
          Raise Finalizar;
       END IF;
    End If;

  -- Gerando os registros cuja base é documento fiscal (X07, X08, X09):
  -- Modelos 01, 1B, 04 e 55 (entrada e saída): C100, C130, C150, C160, C170, C172, C177, C178, C190
  -- Modelos 06 e 28         (entrada)        : C500, C590
  -- Modelos 07,08,8B,09,10,11,26,27          : D100, D190
  -- Modelos 21 e 22         (entrada)        : D500, D590
  -- Gravação da tabela: EFD_CAPA_DOCFIS
    IF efd_layout.VerificaRegPerfil('EFD01') or
       efd_layout.VerificaRegPerfil('EFD30') or
       efd_layout.VerificaRegPerfil('EFD40') or
       efd_layout.VerificaRegPerfil('EFD90') or
       efd_layout.VerificaRegPerfil('EFD79') THEN

      If efd_layout.VerificaRegPerfil('EFD40') AND
         EFD_Dados_Param.getLeiaute = 'EFD100' THEN
             Lib_Proc.Add_Log('=================================================================================== ',0);
             Lib_Proc.Add_Log('Aviso: Geração do Sped Fiscal no layout EFD100, gera os registros D100 e D190 ',0);
             Lib_Proc.Add_Log('somente para Notas Fiscais de entrada de Terceiros (Movimento Entrada/Saída = 1).',0);

      END IF;

		  Status_w := EFD01_30_40_90_Gera.Executar;
  		IF Status_w = -1 THEN
        Lib_Proc.Add_Log('Erro ocorrido no processamento de documentos fiscais (EFD01_30_40_90_Gera.Executar). ' || sqlerrm,0);
  			   RAISE Finalizar;
      ELSE
        COMMIT;
  		END IF;
    END IF;

  -- Gerando os registros cuja base é documento fiscal (X130_NFE_DENEGADA_INUTILIZADA):
  -- Registro C100 e D100: NFe Denegada/Inutilizada
    IF efd_layout.VerificaRegPerfil('EFD01') or
       efd_layout.VerificaRegPerfil('EFD40') THEN
		  Status_w := EFD01_40_nfe_deneg_Gera.Executar;
  		IF Status_w = -1 THEN
        Lib_Proc.Add_Log('Erro ocorrido no processamento de documentos fiscais (EFD01_40_nfe_deneg_Gera.Executar). ' || sqlerrm,0);
  			   RAISE Finalizar;
      ELSE
        COMMIT;
  		END IF;
    END IF;

  -- Gerando os registros cuja base é documento fiscal (EFD_CAPA_DOCFIS, X51):
  -- Registro filho do D100: D160, D161, D162 ¿Itens do Conhecimento de Transporte
  -- Registro filho do D100: D170 ¿ Complemento do Conhecimento Multimodal de Cargas (Código 26)
    IF efd_layout.VerificaRegPerfil('EFD41') THEN
		  Status_w := EFD41_Gera.Executar;
  		IF Status_w = -1 THEN
        Lib_Proc.Add_Log('Erro ocorrido no processamento de documentos fiscais (EFD41_Gera.Executar). ' || sqlerrm,0);
  			   RAISE Finalizar;
      ELSE
        COMMIT;
  		END IF;
    END IF;

    -- Gerando os registros cuja base é documento fiscal (EFD_CAPA_DOCFIS, X51):
    -- Registro filho do D100: D180 ¿ Modais (Código 26)
    IF efd_layout.VerificaRegPerfil('EFD42') THEN
		  Status_w := EFD42_Gera.Executar;
  		IF Status_w = -1 THEN
        Lib_Proc.Add_Log('Erro ocorrido no processamento de documentos fiscais (EFD42_Gera.Executar). ' || sqlerrm,0);
  			   RAISE Finalizar;
      ELSE
        COMMIT;
  		END IF;
    END IF;
		Efd_tab_cadastro.Close_TabCad;

  -- Gerando os registros cuja base é documento fiscal (EFD_CAPA_DOCFIS, X112, X114, X115, X116, X117, X118):
  -- Registros filhos do C100: C100,  C110, C111, C112, C113, C114 e C115 - Informações Complementares da NF
    IF efd_layout.VerificaRegPerfil('EFD02') THEN
  		Status_w := EFD02_Gera.Executar;
  		IF Status_w = -1 THEN
        Lib_Proc.Add_Log('Erro ocorrido no processamento de documentos fiscais (EFD02_Gera.Executar). ' || sqlerrm,0);
  			   RAISE Finalizar;
  		END IF;
    END IF;

  -- Gerando os registros cuja base é documento fiscal (EFD_CAPA_DOCFIS, X49):
  -- Registro filho do C100:  C120 - Importações
    IF efd_layout.VerificaRegPerfil('EFD03') THEN
  		Status_w := EFD03_Gera.Executar;

  		IF Status_w = -1 THEN
        Lib_Proc.Add_Log('Erro ocorrido no processamento de documentos fiscais (EFD03_Gera.Executar). ' || sqlerrm,0);
  			   RAISE Finalizar;
  		END IF;
    END IF;

  -- Gerando os registros cuja base é documento fiscal (EFD_CAPA_DOCFIS, X03, X301, X05, X501):
  -- Registros filhos do C100: C140 e C141 - Fatura
    IF efd_layout.VerificaRegPerfil('EFD04') THEN
      IF efd_dados_param.getIndPagReceb = 'S' THEN
  		  Status_w := EFD04_Nova_Gera.Executar;
        IF Status_w = -1 THEN
          Lib_Proc.Add_Log('Erro ocorrido no processamento de documentos fiscais (EFD04_Nova_Gera.Executar). ' || sqlerrm,0);
            RAISE Finalizar;
        END IF;
      ELSE
  		  Status_w := EFD04_Gera.Executar;
        IF Status_w = -1 THEN
          Lib_Proc.Add_Log('Erro ocorrido no processamento de documentos fiscais (EFD04_Gera.Executar). ' || sqlerrm,0);
            RAISE Finalizar;
        END IF;
      END IF;

    END IF;

  -- Gerando os registros cuja base é documento fiscal (EFD_CAPA_DOCFIS, X112, X113):
  -- Registros filhos do C100: C195 e C197 - Observações de Lançamento
    IF efd_layout.VerificaRegPerfil('EFD05') THEN
  		Status_w := EFD05_Gera.Executar;

  		IF Status_w = -1 THEN
        Lib_Proc.Add_Log('Erro ocorrido no processamento de documentos fiscais (EFD05_Gera.Executar). ' || sqlerrm,0);
  			   RAISE Finalizar;
      ELSE
       commit;
  		END IF;
    END IF;

  -- Gerando os registros cuja base é documento fiscal (EFD_CAPA_DOCFIS, EFD_ITEM_DOCFIS):
  -- Registros filhos do C100: C176
    IF efd_layout.VerificaRegPerfil('EFD06') THEN
  		Status_w := EFD06_Gera.Executar;

  		IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de documentos fiscais (EFD06_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
      ELSE
       commit;
  		END IF;
    END IF;

  -- Gerando os registros cuja base é documento fiscal (EFD_CAPA_DOCFIS, EFD_ITEM_DOCFIS):
  -- Registros filhos do C100: C173 Medicamentos
    IF efd_layout.VerificaRegPerfil('EFD07') THEN
  		Status_w := EFD07_Gera.Executar;

  		IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de documentos fiscais (EFD07_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
      ELSE
       commit;
  		END IF;
    END IF;

   -- Gerando os registros cuja base é documento fiscal (EFD_CAPA_DOCFIS,EFD_ITEM_DOCFIS ):
   -- Registros filhos do C100: C174 Armas de fogo
    IF efd_layout.VerificaRegPerfil('EFD08') THEN
  		Status_w := EFD08_Gera.Executar;

  		IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de documentos fiscais (EFD08_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
      ELSE
       commit;
  		END IF;
    END IF;

   -- Gerando os registros cuja base é documento fiscal (EFD_CAPA_DOCFIS,EFD_ITEM_DOCFIS ):
   -- Registros filhos do C100: C175 Veículos novos
    IF efd_layout.VerificaRegPerfil('EFD09') THEN
  		Status_w := EFD09_Gera.Executar;
  		IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de documentos fiscais (EFD09_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
      ELSE
       commit;
  		END IF;
    END IF;

    -- Gerando os registros cuja base é documento fiscal (EFD_CAPA_DOCFIS, EFD_ITEM_DOCFIS):
  -- Registros filhos do C100: C171 Armazenament de Combustivel

    IF efd_layout.VerificaRegPerfil('EFD10') THEN
  		Status_w := EFD10_Gera.Executar;
  		IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de documentos fiscais (EFD10_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
      ELSE
       commit;
  		END IF;
    END IF;

   -- Gerando os registros cuja base é documento fiscal (EFD_CAPA_DOCFIS):
  -- Registros filhos do C100: C105 Operações c/ ICMS-ST Recolhido p/UF Diferente do Destinatário

    IF efd_layout.VerificaRegPerfil('EFD11') THEN
  		Status_w := EFD11_Gera.Executar;
  		IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de documentos fiscais (EFD11_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
      ELSE
       commit;
  		END IF;
    END IF;

  -- Gerando os registros cuja base é Redução Z dos Equipamentos ECF (X991, X992)
  -- Modelos 02, 2D               : C400, C405, C410, C420
  -- Modelos 2E, 13, 14, 15 e 16  : D350, D355, D360, D365
  -- Gravação da tabela: EFD_CAPA_REDUCAO_ECF
    IF efd_layout.VerificaRegPerfil('EFD20') or
       efd_layout.VerificaRegPerfil('EFD80') THEN
  		Status_w := EFD20_80_Gera.Executar;
  		IF Status_w = -1 THEN
        Lib_Proc.Add_Log('Erro ocorrido no processamento das Reduções Z do Equipamento ECF (EFD20_80_Gera.Executar). ' || sqlerrm,0);
  			   RAISE Finalizar;
      ELSE
        COMMIT;
  		END IF;
    END IF;

  -- Gerando os registros cuja base é Cupom Fiscal dos Equipamentos ECF  (EFD_CAPA_REDUCAO_ECF, X993, X994):
  -- Modelos 02, 2D               : C425, C460, C470, C490 (Registros filhos do C400, C405)
    IF efd_layout.VerificaRegPerfil('EFD21') THEN
  		Status_w := EFD21_Gera.Executar;

  		IF Status_w = -1 THEN
        Lib_Proc.Add_Log('Erro ocorrido no processamento dos Cupons Fiscais do Equipamento ECF (EFD21_Gera.Executar). ' || sqlerrm,0);
  			   RAISE Finalizar;
      ELSE
       COMMIT;
  		END IF;
    END IF;

  -- Gerando os registros cuja base é Cupom Fiscal dos Equipamentos ECF  (x991, X993, X994):
  -- Modelos 02, 2D               : C495
  -- CH54684 -- Retirada da EFD21_GERA a geração do registro C495, criando a package de geração EFD22_gera,
  --            específica para este registro.
    IF efd_layout.VerificaRegPerfil('EFD22') THEN
      Status_w := EFD22_Gera.Executar;
  		IF Status_w = -1 THEN
        Lib_Proc.Add_Log('Erro ocorrido no processamento dos Cupons Fiscais do Equipamento ECF (EFD22_Gera.Executar). ' || sqlerrm,0);
  			   RAISE Finalizar;
      ELSE
       COMMIT;
  		END IF;
    END IF;

    -- Gerando os registros cuja base é Cupom Fiscal Eletronico
    -- Geração do Registro do Bloco C – Registros C800, C850:
    IF efd_layout.VerificaRegPerfil('EFD23') THEN
  		Status_w := EFD23_Gera.Executar;
  		IF Status_w = -1 THEN
        Lib_Proc.Add_Log('Erro ocorrido no processamento dos Cupons Fiscais Eletronico CFE (EFD23_Gera.Executar).  ' || sqlerrm,0);
  			   RAISE Finalizar;
      ELSE
        COMMIT;
  		END IF;
    END IF;
    -- Gerando os registros cuja base é Cupom Fiscal Eletronico
    -- Geração do Registro do Bloco C – Registros C860 e C890:

    IF efd_layout.VerificaRegPerfil('EFD24') THEN
  		Status_w := EFD24_Gera.Executar;
  		IF Status_w = -1 THEN
        Lib_Proc.Add_Log('Erro ocorrido no processamento dos Cupons Fiscais Eletronico CFE (EFD24_Gera.Executar).  ' || sqlerrm,0);
  			   RAISE Finalizar;
      ELSE
        COMMIT;
  		END IF;
    END IF;

  -- Gerando os registros C300, C310, C320, C321 - Registro de Informações sobre NF Venda a consumidor - Modelo 02
    IF efd_layout.VerificaRegPerfil('EFD25') THEN
  		Status_w := EFD25_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Informações sobre NF Venda a consumidor - Modelo 02  (EFD25_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

  -- Gerando os registros C350, C370, C390 - Registro de Informações sobre NF Venda a consumidor - Modelo 02
    IF efd_layout.VerificaRegPerfil('EFD26') THEN
  		Status_w := EFD26_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Informações sobre NF Venda a consumidor - Modelo 02  (EFD26_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

  -- Gerando os registros cuja base é Cupom Fiscal dos Equipamentos ECF  (EFD_CAPA_REDUCAO_ECF, X993, X994):
  -- Modelos 2E, 13, 14, 15 e 16  : D370, D390 (Registros filhos do D350, D355)
    IF efd_layout.VerificaRegPerfil('EFD81') THEN
  	Status_w := EFD81_Gera.Executar;

  		IF Status_w = -1 THEN
        Lib_Proc.Add_Log('Erro ocorrido no processamento dos Cupons Fiscais do Equipamento ECF (EFD81_Gera.Executar). ' || sqlerrm,0);
  			   RAISE Finalizar;
      ELSE
       COMMIT;
  		END IF;
    END IF;

  -- Gerando os registros cuja base é Apuração do ICMS (ITEM_APURAC_CALC, ITEM_APURAC_DISCR)
  -- Gerando os registros E100, E110, E111, E112, E113, E116 - Apuração do ICMS
    IF efd_layout.VerificaRegPerfil('EFD71') THEN
  		Status_w := EFD71_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento da Apuração do ICMS (EFD71_Gera.Executar). ' || sqlerrm,0);
     			 RAISE Finalizar;
      ELSE
          COMMIT;
      END IF;
    END IF;

  -- EFD88 - Geração da Sub-apuração - OS2931-F
  -- Gerando os registros cuja base é Sub Apuração do ICMS (ITEM_APURAC_CALC, ITEM_APURAC_DISCR)
  -- Gerando os registros 1900, 1910, 1920, 1921, 1922, 1923, 1925, 1926 - Apuração do ICMS
    IF efd_layout.VerificaRegPerfil('EFD88') THEN
  		Status_w := EFD88_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento da Sub-Apuração do ICMS (EFD88_Gera.Executar). ' || sqlerrm,0);
     			 RAISE Finalizar;
      ELSE
          COMMIT;
      END IF;
    END IF;

   -- Gerando os registros cuja base é Apuração do ICMS-ST (RESUMO_APUR_ST, ITEM_APURAC_SUBST)
   -- Gerando os registros E200, E210, E220, E230, E240, E250 - Apuração do ICMS-ST
    IF efd_layout.VerificaRegPerfil('EFD72') THEN
    	Status_w := EFD72_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento da Apuração do ICMS-ST (EFD72_Gera.Executar). ' || sqlerrm,0);
     			 RAISE Finalizar;
      ELSE
          COMMIT;
      END IF;
    END IF;

   -- Gerando os registros cuja base é APURAÇÃO DO ICMS DIFERENCIAL DE ALÍQUOTA - UF ORIGEM/DESTINO (EC 87/15) (RESUMO_APUR_DIFAL, ITEM_APURAC_DIFAL)
   -- Gerando os registros E300, E310, E311, E312, E313, E316
    IF efd_layout.VerificaRegPerfil('EFD82') THEN
    	Status_w := EFD82_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento da Apuração do ICMS Diferencial de Alíquota - Uf Origem/Destino(EC 87/15) (EFD82_Gera.Executar). ' || sqlerrm,0);
     			 RAISE Finalizar;
      ELSE
          COMMIT;
      END IF;
    END IF;

   -- Gerando os registros cuja base é Apuração do IPI Normal e da IN SRF 446/04 (ITEM_APURAC_CALC, ITEM_APURAC_DISCR, IPT_RESUMO_APUR)
   -- Gerando os registros E500, E510, E520, E530 - Apuração do IPI

    IF efd_layout.VerificaRegPerfil('EFD73') THEN
  		Status_w := EFD73_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento da Apuração do IPI (EFD73_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
      ELSE
        COMMIT;
  		END IF;
    END IF;

  -- Gerando os registros 1200 e 1210 - Registro de Informações sobre Controle de Créditos Fiscais
    IF efd_layout.VerificaRegPerfil('EFD74') THEN
  		Status_w := EFD74_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Informações sobre Controle de Créditos Fiscais (EFD74_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

  -- Gerando os registros 1100 - Registro de Informações sobre Exportação
    IF efd_layout.VerificaRegPerfil('EFD75') THEN
  		Status_w := EFD75_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Informações sobre Exportação (EFD75_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

  -- Gerando os registros 1390 - Registro de Informações sobre Exportação
    IF efd_layout.VerificaRegPerfil('EFD93') THEN
  		Status_w := EFD93_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Informações sobre Usinas (EFD93_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

    -- Gerando os registros cuja base é documento fiscal Utilities(X42, X43 e Convênio 115):
    -- Modelos 21 e 22         (Saídas)        : D500, D510, D530, D590
    IF efd_layout.VerificaRegPerfil('EFD30','Saida') or
       efd_layout.VerificaRegPerfil('EFD90','Saida') or
       (efd_layout.VerificaRegPerfil('EFD79')         and 
      ((EFD_Dados_Param.getIndGer1400 = '2' and efd_layout.IndTpApresent = 'A') or
       (EFD_Dados_Param.getIndGer1400 = '1' /*and efd_layout.IndTpApresent = 'A'*/ ))) THEN
		  Status_w := EFD30_90_Saida_Gera.Executar;
  		IF Status_w = -1 THEN
        Lib_Proc.Add_Log('Erro ocorrido no processamento de documentos Utilities (EFD30_90_Saida_Gera.Executar). ' || sqlerrm,0);
  			   RAISE Finalizar;
      ELSE
        COMMIT;
  		END IF;
    END IF;

    -- Gerando os registros cuja base é documento fiscal Utilities(X42, X43 e Convênio 115):
    -- Modelo 06         (Saídas)        : 1500, 1510
    IF efd_layout.VerificaRegPerfil('EFD33') THEN
		  Status_w := EFD33_Gera.Executar;
  		IF Status_w = -1 THEN
        Lib_Proc.Add_Log('Erro ocorrido no processamento de documentos Utilities (EFD33_Gera.Executar). ' || sqlerrm,0);
  			   RAISE Finalizar;
      ELSE
        COMMIT;
  		END IF;
    END IF;

    -- Gerando os registros cuja base é documento fiscal Utilities(X42, X43 e Convênio 115):
    -- Documentos Modelos 06, 28 e 29: Gerando os registros C600, C601, C610 e C690
    IF efd_layout.VerificaRegPerfil('EFD31') or
      (efd_layout.VerificaRegPerfil('EFD79') and
      ((EFD_Dados_Param.getIndGer1400 = '2' and efd_layout.IndTpApresent = 'B') or
       (EFD_Dados_Param.getIndGer1400 = '1' and efd_layout.IndTpApresent = 'B' ))) THEN
    	Status_w := EFD31_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Informações sobre Utilities (EFD91_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

    -- Gerando os registros cuja base é documento fiscal Utilities(X42, X43 e Convênio 115):
    -- Documentos Modelos 01, 06 e 28: Gerando os registros C700, C790 e C791
    IF efd_layout.VerificaRegPerfil('EFD32') THEN
  		Status_w := EFD32_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Informações sobre Utilities (EFD92_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;


    -- Gerando os registros cuja base é documento fiscal (X07 e X08):
    -- Documentos Modelos 13, 14, 15, 16 e 18: Gerando os registros D300, D301 e D310
    IF efd_layout.VerificaRegPerfil('EFD51') THEN
  		Status_w := EFD51_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Informações sobre Utilities (EFD51_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

    -- Gerando os registros cuja base é documento fiscal (X07 e X08):
    -- Documentos Modelos 13, 14, 15, 16 e 18: Gerando os registros D300, D301 e D310
    IF efd_layout.VerificaRegPerfil('EFD52') THEN
  		Status_w := EFD52_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Informações sobre Utilities (EFD52_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

    -- Gerando os registros cuja base é documento fiscal Utilities(X42, X43 e Convênio 115):
    -- Documentos Modelos 21 e 22: Gerando os registros D600, D610 e D690
    IF ( efd_layout.VerificaRegPerfil('EFD91')  and EFD_DADOS_PARAM.getIndConvIcms <> 'S' ) or
      (efd_layout.VerificaRegPerfil('EFD79') and
      ((EFD_Dados_Param.getIndGer1400 = '2' and efd_layout.IndTpApresent = 'B'  ) or
       (EFD_Dados_Param.getIndGer1400 = '1' and efd_layout.IndTpApresent = 'B'  ))) THEN
  		Status_w := EFD91_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Informações sobre Utilities (EFD91_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF; 

    -- Gerando os registros cuja base é documento fiscal Utilities(X42, X43 e Convênio 115):
    -- Documentos Modelos 21 e 22: Gerando os registros D695, D696 e D697
    IF efd_layout.VerificaRegPerfil('EFD92') THEN
  		Status_w := EFD92_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Informações sobre Utilities (EFD92_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

  -- Gerando os registros 1300, 1310, 1320 - Movimentos de Informações Combustíveis
    IF efd_layout.VerificaRegPerfil('EFD76') THEN
  		Status_w := EFD76_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Movimentação de Combustíveis (EFD76_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

   -- Gerando os registros 1350, 1360, 1370 - Cadastro de Informações Combustíveis
    IF efd_layout.VerificaRegPerfil('EFD77') THEN
  		Status_w := EFD77_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Cadastro de Informações Combustíveis (EFD77_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

   -- Gerando os registros 1600 - Cadastro de Cartão de Crédito/Débito
    IF efd_layout.VerificaRegPerfil('EFD78') THEN
  		Status_w := EFD78_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Cadastro de Cartão de Crédito/Débito (EFD78_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

   -- Gerando os registros 1700 e 1710 - DOCUMENTOS FISCAIS UTILIZADOS e DOCUMENTOS FISCAIS CANCELADOS/INUTILIZADOS
    IF efd_layout.VerificaRegPerfil('EFD85') THEN
  		Status_w := EFD85_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Documentos Fiscais Utilizados e Cancelados/Inutilizados (EFD85_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

   -- Gerando os registros 1800 - DCTA - DEMONSTRATIVO DE CRÉDITO DO ICMS SOBRE TRANSPORTE AÉREO
    IF efd_layout.VerificaRegPerfil('EFD86') THEN
  		Status_w := EFD86_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de DCTA (EFD86_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

    -- Gerando os registros do bloco G
    IF efd_layout.VerificaRegPerfil('EFD87') THEN
      If Efd_Dados_Param.getIndGerCiap  = 'S' Then
         Status_w := EFD87_Gera.Executar;
         IF Status_w = -1 THEN
            Lib_Proc.Add_Log('Erro ocorrido no processamento de ICMS Ativo Permanente - CIAP (EFD87_Gera.Executar). ' || sqlerrm,0);
		        RAISE Finalizar;
	       END IF;
      Else
         If Efd_Dados_Param.getModelo102  = 'C' Then
            If Efd_Dados_Param.getTipoMod102 in ('1','2','3') Then
              
              If Efd_Dados_Param.getIndGerPerAntBlG = 'S' Then /* MFS-14642 DW - DEMONSTRAÇÃO DAS INFORMAÇÕES DE FORMA EXTEMPORÂNEA (NEXTEL) */
                 Status_w := EFD87_Per_Ant_Modelo_C_Gera.Executar;
                 IF Status_w = -1 THEN
                    Lib_Proc.Add_Log('Erro ocorrido no processamento de ICMS Ativo Permanente - CIAP (EFD87_Per_Ant_Modelo_C_Gera.Executar). ' || sqlerrm,0);
                    RAISE Finalizar;
                 END IF;
              Else
                 Status_w := EFD87_modelo_C_Gera.Executar;
                 IF Status_w = -1 THEN
                    Lib_Proc.Add_Log('Erro ocorrido no processamento de ICMS Ativo Permanente - CIAP (EFD87_modelo_C_Gera.Executar). ' || sqlerrm,0);
                    RAISE Finalizar;
                 END IF;
              End If; 
            Else
               If Efd_Dados_Param.getIndGerPerAntBlG = 'S' Then /* MFS-14642 DW - DEMONSTRAÇÃO DAS INFORMAÇÕES DE FORMA EXTEMPORÂNEA (NEXTEL) */
                   Status_w := EFD87_Per_Ant_Modelo_D_Gera.Executar;
                   IF Status_w = -1 THEN
                      Lib_Proc.Add_Log('Erro ocorrido no processamento de ICMS Ativo Permanente - CIAP (EFD87_modelo_D_Gera.Executar). ' || sqlerrm,0);
                      RAISE Finalizar;
                   END IF;
               Else
                   Status_w := EFD87_modelo_D_Gera.Executar;
                   IF Status_w = -1 THEN
                      Lib_Proc.Add_Log('Erro ocorrido no processamento de ICMS Ativo Permanente - CIAP (EFD87_modelo_D_Gera.Executar). ' || sqlerrm,0);
                      RAISE Finalizar;
                   END IF;
               End If;     
            End If;
        ElsIf Efd_Dados_Param.getModelo102 = 'D' Then
          
             If Efd_Dados_Param.getIndGerPerAntBlG = 'S' Then /* MFS-14642 DW - DEMONSTRAÇÃO DAS INFORMAÇÕES DE FORMA EXTEMPORÂNEA (NEXTEL) */
                 Status_w := EFD87_Per_Ant_Modelo_D_Gera.Executar;
                 IF Status_w = -1 THEN
                    Lib_Proc.Add_Log('Erro ocorrido no processamento de ICMS Ativo Permanente - CIAP (EFD87_modelo_D_Gera.Executar). ' || sqlerrm,0);
                    RAISE Finalizar;
                 END IF;
             Else
                 Status_w := EFD87_modelo_D_Gera.Executar;
                 IF Status_w = -1 THEN
                    Lib_Proc.Add_Log('Erro ocorrido no processamento de ICMS Ativo Permanente - CIAP (EFD87_modelo_D_Gera.Executar). ' || sqlerrm,0);
                    RAISE Finalizar;
                 END IF;
             End If;    
        End If;
      End If;
    END IF;

		-- Gerando os registros com informações sobre o valor agregado por município:
    IF efd_layout.VerificaRegPerfil('EFD79') THEN
  		Status_w := EFD79_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Informações sobre Valor Agregado por Município (EFD79_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

		-- Gerando os registros com informações sobre o Inventário:
    IF efd_layout.VerificaRegPerfil('EFD70') THEN
  		Status_w := EFD70_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Informações sobre Inventário (EFD70_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

		-- Gerando os registros com informações sobre Estoque Escriturado: - K200
    IF efd_layout.VerificaRegPerfil('EFD45') THEN
  		Status_w := EFD45_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Informações sobre Estoque Escriturado (EFD45_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

		-- Gerando os registros com informações sobre Outras Movimentações Internas: - K220
    IF efd_layout.VerificaRegPerfil('EFD46') THEN
  		Status_w := EFD46_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Informações sobre Outras Movimentações Internas (EFD46_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

     -- Gerando os Registros K230 (Itens Produzidos) e K235 (Insumos Consumidos)
    IF efd_layout.VerificaRegPerfil('EFD47') THEN
      If Efd_Dados_Param.getIndOrdOpK230 = 'S' Then
        Status_w := EFD47_Sem_OP_Gera.Executar;
        IF Status_w = -1 THEN
           Lib_Proc.Add_Log('Erro ocorrido no processamento de Itens Produzidos e Insumos Consumidos (EFD47_Sem_OP_Gera.Executar). ' || sqlerrm,0);
           RAISE Finalizar;
        END IF;
      else
        Status_w := EFD47_Gera.Executar;
        IF Status_w = -1 THEN
           Lib_Proc.Add_Log('Erro ocorrido no processamento de Itens Produzidos e Insumos Consumidos (EFD47_Gera.Executar). ' || sqlerrm,0);
           RAISE Finalizar;
        END IF;
      end if;
    END IF;

    -- Gerando os Registros K210 (Desmontagem de Mercadorias - Item de Origem) e K215 (Desmontagem de Mercadorias - Itens de Destino)
    IF efd_layout.VerificaRegPerfil('EFD53') THEN
      If Efd_Dados_Param.getIndOrdOpK210 = 'S' Then
        Status_w := EFD53_Sem_OP_Gera.Executar;
        IF Status_w = -1 THEN
           Lib_Proc.Add_Log('Erro ocorrido no processamento de Itens de Desmontagem de Mercadorias (EFD53_Sem_OP_Gera.Executar). ' || sqlerrm,0);
           RAISE Finalizar;
        END IF;
      else
        Status_w := EFD53_Gera.Executar;
        IF Status_w = -1 THEN
           Lib_Proc.Add_Log('Erro ocorrido no processamento de Itens  de Desmontagem de Mercadorias (EFD53_Gera.Executar). ' || sqlerrm,0);
           RAISE Finalizar;
        END IF;
      end if;
    END IF;

    -- Gerando os Registros K260 (Reprocessamento/Reparo de Produto/Insumo) e K265 (Reprocessamento/Reparo - Mercadorias Consumidas e/ou Retornadas)
    IF efd_layout.VerificaRegPerfil('EFD54') THEN
      If Efd_Dados_Param.getIndOrdOpK260 = 'S' Then
        Status_w := EFD54_Sem_OP_Gera.Executar;
        IF Status_w = -1 THEN
           Lib_Proc.Add_Log('Erro ocorrido no processamento de Itens de Reprocessamento/Reparo (EFD54_Sem_OP_Gera.Executar). ' || sqlerrm,0);
           RAISE Finalizar;
        END IF;
      else
        Status_w := EFD54_Gera.Executar;
        IF Status_w = -1 THEN
           Lib_Proc.Add_Log('Erro ocorrido no processamento de Itens  de Reprocessamento/Reparo (EFD54_Gera.Executar). ' || sqlerrm,0);
           RAISE Finalizar;
        END IF;
      end if;
    END IF;

    -- Gerando os Registros K270 (Correção de Apontamento) e K275 (Correção de Apontamento - Insumos)
    IF efd_layout.VerificaRegPerfil('EFD55') THEN
     /* If Efd_Dados_Param.getIndOrdOpK230 = 'S' Then
        Status_w := EFD47_Sem_OP_Gera.Executar;
        IF Status_w = -1 THEN
           Lib_Proc.Add_Log('Erro ocorrido no processamento de Itens Produzidos e Insumos Consumidos (EFD47_Sem_OP_Gera.Executar). ' || sqlerrm,0);
           RAISE Finalizar;
        END IF;
      else    */
        Status_w := EFD55_Gera.Executar;
        IF Status_w = -1 THEN
           Lib_Proc.Add_Log('Erro ocorrido no processamento de Correção de Apontamento (EFD55_Gera.Executar). ' || sqlerrm,0);
           RAISE Finalizar;
        END IF;
     /* end if;*/
    END IF;

    -- Gerando os Registros K280 (Correção de Apontamento - Estoque Escriturado)
    IF efd_layout.VerificaRegPerfil('EFD56') THEN
        Status_w := EFD56_Gera.Executar;
        IF Status_w = -1 THEN
           Lib_Proc.Add_Log('Erro ocorrido no processamento de Correção de Apontamento - Estoque Escriturado (EFD56_Gera.Executar). ' || sqlerrm,0);
           RAISE Finalizar;
        END IF;
    END IF;


     -- Gerando os Registros K250 (Itens Produzidos Terceiros) e K255 (Insumos Consumidos)
    IF efd_layout.VerificaRegPerfil('EFD48') THEN
  		Status_w := EFD48_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Industrialização Efetuada p/Terceiros - Itens Produzidos e Insumos Consumidos (EFD48_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

		-- Gerando os registros com informações sobre Período de Apuração do ICMS/IPI: - K100
    IF efd_layout.VerificaRegPerfil('EFD44') THEN
  		Status_w := EFD44_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Informações sobre Período de Apuração do ICMS/IPI (EFD44_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;
		Efd_tab_cadastro.Close_TabCad;

  -- Gerando os registros 0000, 0005, 0015 e 0100 - Dados do Contribuinte e Contabilista
    IF efd_layout.VerificaRegPerfil('EFD61') THEN
      Status_w := EFD61_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de dados do estabelecimento e contador (EFD61_Gera.Executar). ' || sqlerrm,0);
  			    RAISE Finalizar;
  		END IF;
    END IF;
		Efd_tab_cadastro.Close_TabCad;

  -- Gerando o registro 0150 e 0175 - Cadastro de Participantes e Suas Alterações
    IF efd_layout.VerificaRegPerfil('EFD62') THEN
  		Status_w := EFD62_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de dados do participante (EFD62_Gera.Executar). ' || sqlerrm,0);
  			    RAISE Finalizar;
  		END IF;
    END IF;
		Efd_tab_cadastro.Close_TabCad;

  -- Gerando os registros 0200, 0205, 0206 e 0220 - Cadastro de Produto/Serviço
    IF efd_layout.VerificaRegPerfil('EFD64') THEN
  		Status_w := EFD64_Gera.Executar('N');
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de dados do produto (EFD64_Gera.Executar). ' || sqlerrm,0);
     			 RAISE Finalizar;
      ELSE
        COMMIT;
  		END IF;
    END IF;
		Efd_tab_cadastro.Close_TabCad;

  -- Gerando os registros 0200, 0205, 0206 e 0220 - Cadastro de Produto/Serviço
    IF efd_layout.VerificaRegPerfil('EFD64') THEN
  		Status_w := EFD64_Gera.Executar('S');
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de dados do produto (EFD64_Gera.Executar). ' || sqlerrm,0);
     			 RAISE Finalizar;
      ELSE
        COMMIT;
  		END IF;
    END IF;
		Efd_tab_cadastro.Close_TabCad;

  -- Gerando os registros 0190 - Cadastro de Unidade de Medida
  -- OBS: A execução do grupo EFD63 (EFD63_Gera) deve ser após a execução do EFD64 (EFD64_Gera).
  --      A EFD63_Gera grava unidades de medida que serão processadas na EFD64_Gera.
    IF efd_layout.VerificaRegPerfil('EFD63') THEN
    	Status_w := EFD63_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de medida (EFD63_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;
		Efd_tab_cadastro.Close_TabCad;

  -- Gerando os registros 0400 - Cadastro de Natureza de Operação
    IF efd_layout.VerificaRegPerfil('EFD65') THEN
  		Status_w := EFD65_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de natureza de operação (EFD65_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;
		Efd_tab_cadastro.Close_TabCad;

  -- Gerando os registros 0450 e 0460 - Cadastro de Informações Complementares e Observação

    IF efd_layout.VerificaRegPerfil('EFD66') THEN
  		Status_w := EFD66_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de observações (EFD66_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;
		Efd_tab_cadastro.Close_TabCad;


-- Gerando os registros 0500 - Cadastro do Plano de Contas

    IF efd_layout.VerificaRegPerfil('EFD67') THEN
  		Status_w := EFD67_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento do Plano de Contas (EFD67_Gera.Executar). ' || sqlerrm,0);

         RAISE Finalizar;
  		END IF;
    END IF;
		Efd_tab_cadastro.Close_TabCad;

  -- Gerando os registros 0300 e 0305 - Cadastro de Bens ou Componentes do Ativo Imobilizado e Utilização do bem

    IF efd_layout.VerificaRegPerfil('EFD68') THEN
  		Status_w := EFD68_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Cadastro de Bens ou Componentes do Ativo Imobilizado e Utilização do bem(EFD68_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;
		Efd_tab_cadastro.Close_TabCad;

     -- Gerando os registros 0600 - Cadastro de Centro de Custos

    IF efd_layout.VerificaRegPerfil('EFD69') THEN
  		Status_w := EFD69_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Centro de Custos (EFD69_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;
		Efd_tab_cadastro.Close_TabCad;

  -- Gerando os registros 1010 - Registro de Informações sobre a Obrigatoriedade do bloco 1
    IF efd_layout.VerificaRegPerfil('EFD94') THEN
  		Status_w := EFD94_Gera.Executar;
      IF Status_w = -1 THEN
         Lib_Proc.Add_Log('Erro ocorrido no processamento de Informações sobre a Obrigatoriedade do bloco 1 (EFD94_Gera.Executar). ' || sqlerrm,0);
  			 RAISE Finalizar;
  		END IF;
    END IF;

  -- Gerando o Bloco 9 e os registros de Termo de Abertura e Encerramento de todos os blocos
		Status_w := EFD00_Gera.Executar;
    IF Status_w = -1 THEN
       Lib_Proc.Add_Log('Erro ocorrido no processamento do bloco 9 e termos de abertura e encerramento (EFD00_Gera.Executar). ' || sqlerrm,0);
			 RAISE Finalizar;
		END IF;


		COMMIT;

/*			Rel_Conferencia(Pperfil,
								 Pleiaute,
								 Pdataini,
								 Pdatafim,
								 Pfinalidade,
								 Mcod_Estab);
	*/
		Lib_Proc.CLOSE;

		RETURN Procid;
	EXCEPTION
		WHEN Finalizar THEN
			IF Length(SQLERRM) <> 0 THEN
				Lib_Proc.Add_Log('Erro ao gerar SPED: ' || Substr(SQLERRM, 1, 200), 0);
			END IF;
			Lib_Proc.CLOSE;
			RETURN Procid;
	END;

	PROCEDURE Teste IS
		Resultado INTEGER := 0;
	BEGIN

		Lib_Parametros.Salvar('EMPRESA', '076');

		Resultado := EFD_SPED_FPROC.Executar(Pdataini         => '01/1/2017',
                                         Pdatafim         => '31/1/2017',
                                         Pleiaute         => 'EFD110',
                                         Pperfil          => 'K01',
                                         Pfinalidade      => '00',
                                         Pdatainv         => '',
                                         PdataSldLpd      => '',
                                         PqtdMaxlog       => '0',
                                         Pindcentr        => 'N',
                                         pMultEmp         => 'N',
                                         pUf              => '%',
                                         Pcod_Estab       => '0001');

  dbms_output.put_line('Proc_Id:'|| resultado);

	END;


	PROCEDURE TesteEfd05 IS
		Resultado INTEGER := 0;
	BEGIN

		Lib_Parametros.Salvar('EMPRESA', '076');

		Resultado := EFD_SPED_FPROC.Executar(Pleiaute  => 'EFD100',
															Pperfil          => '01',
															Pdataini         => '01/01/2007',
															Pdatafim         => '31/01/2007',
															Pfinalidade      => '00',
                              Pdatainv         => '05/01/2009',
                              PdataSldLpd      => '',
                              PqtdMaxlog       =>  '0',
                              Pindcentr        => 'N',
                              pMultEmp         => 'N',
                              pUf              => '%',
															Pcod_Estab       => 'GMB-RS');

  dbms_output.put_line('Proc_Id:'|| resultado);

	END;

END EFD_SPED_FPROC;
/
