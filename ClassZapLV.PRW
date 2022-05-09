#INCLUDE 'TOTVS.CH'
#INCLUDE 'TOPCONN.CH'

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Classe whatsapp
@type   		Class	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			
@return			Nil 			
*****************************************************************************************************/
Class ZAPLV 

    Data _cMsg              // Mensagem de Log
    Data _cNota             // Numero da nota
    Data _nCntBol           // Quantidade de boleto para enviar ao cliente
    Data _nCntOS            // Origem da ordem de servico
    Data _nCntOrc           // Orcamento 
    Data _cSerie            // Serie da nota
    Data _cAlias            // Alias Query Danfe 
    Data _cAliasBol         // Alias Query Boleto  
    Data _cFormPg           // Forma de pagamento
    Data _cOc               // Numero do orcamento
    Data _lEnvio            // Retorno do envio da mensagem
    Data aZap               // Array contendo o conteudo do retorno da mensagem 

    Method New() CONSTRUCTOR

    Method mQryzap()        // Metodo validacoes
    Method mLoop()          // Metodo loop
    Method mValid()         // Metodo para preparar o documento
    Method mPreparaDoc()    // Metodo para gerar o xml
    Method mResetEnvir()    // Metodo para resetar o ambiente
    Method mXML()           // Metodo para gerar o xml
    Method mDanfe()         // Metodo para gerar a danfe
    Method mPrepMsg()       // Metodo para prepara a mensagem de envio 
    Method mEnvioMsg()      // Metodo para enviar a mensagem 
    Method mReckLock()      // Metodo para gravar os dados de envio na tabela
    Method mTreatment()     // Metodo para tratar o conout
    Method mChoiceBol()     // Metodo para definir o tipo do boleto     
    Method mBolItau()       // Metodo Boleto Itau
    Method mBolBB()         // Metodo Boleto Banco do Brasil
    Method mBolQr()         // Metodo para gerar a query do boleto
    Method mSpaceField()    // Metodo para tratar o tamanho dos campos
    Method mLockValid()     // Metodo para gravar o erro da validacao
    Method mPrepReck()      // Metodo para prepara as informacoes na ZZX
    Method mPrpBol()        // Metodo para preparar variaveis do boleto 
    Method mTrackOs()       // Metodo para rastrear a OS 
    Method mVldOs()         // Metodo para validar a OS 
    Method mOS()            // Metodo de condicoes da os
    Method mZerarVar()      // Metodo para zerar as variaveis
    Method mRelRPS()        // Metodo para gravar os parametros RPS
    Method mDefNfSerie()    // Metodo para definir o RPS
    Method mDefBol()        // Metodo para definir o boleto 
    Method mCloseArea()     // Metodo para fechar areas das tabelas 
    Method Budget()         // Metodo para rastrear o orcamento 
    Method mMailBol()       // Metodo para enviar o boleto por email
    Method mPrepHtml()      // Metodo para prepara o html para envio por email

EndClass 

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Construtor da classe
@type   		Method	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			
@return			Self			
*****************************************************************************************************/
Method New() class ZAPLV

    Self:_cMsg          := ""
    Self:_cNota         := ""
    Self:_cSerie        := ""
    Self:_cFormPg       := ""
    Self:_cOc           := ""
    Self:_cAlias        := GetNextAlias()
    Self:_lEnvio        := .T.
    Self:aZap           := {}
    Self:_nCntBol       := 0
    Self:_nCntOS        := 0
    Self:_nCntOrc        := 0
    Self:_cAliasBol     := ""

Return Self


/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Se não tiver ambiente aberto, Reseta o ambiente e abre ele novamente
@type   		Method	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			
@return		    Nil 		
*****************************************************************************************************/
Method mResetEnvir() Class ZAPLV 

Local cUser     := "Admin" 
Local cEmpAux   := "01"
Local cFilAux   := "010101"
Local cPass     := MemoRead("\x_senha\senha.txt")

    If Select("SX2") == 0
        RpcClearEnv()
        RpcSetEnv(cEmpAux, cFilAux, cUser, AllTrim(cPass), "FAT")
    EndIf

Return


/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Monta a consulta das NFs, que tenham chave de acesso,
                e foi colocado uma data de corte para não processar NFs antigas.
@type   		Method	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			
@return			Nil 			
*****************************************************************************************************/
Method mQryzap() Class ZAPLV 

Local _cQryDoc := "" 
Local dDataZp  := GetNewPar("MV_DATAZAP", Date())

    _cQryDoc := " SELECT                                                        " + CRLF
    _cQryDoc += " 	    DISTINCT(F2_DOC),                                       " + CRLF
    _cQryDoc += " 	    F2_FILIAL,                                              " + CRLF
    _cQryDoc += " 	    F2_SERIE,                                               " + CRLF
    _cQryDoc += " 	    F2_CLIENTE,                                             " + CRLF
    _cQryDoc += " 	    F2_LOJA,                                                " + CRLF
    _cQryDoc += " 	    F2_X_ZAPDA,                                             " + CRLF
    _cQryDoc += " 	    F2_PREFIXO,                                             " + CRLF
    _cQryDoc += " 	    F2_TIPO,                                                " + CRLF
    _cQryDoc += " 	    F2_EMISSAO,                                             " + CRLF
    _cQryDoc += " 	    F2_NFELETR,                                             " + CRLF
    _cQryDoc += " 	    SF2.R_E_C_N_O_ AS SF2REC,                               " + CRLF
    _cQryDoc += " 	    A1_DDD,                                                 " + CRLF
    _cQryDoc += " 	    A1_TEL                                                  " + CRLF
    _cQryDoc += " FROM                                                          " + CRLF
    _cQryDoc += " 	" + RetSQLName("SF2") + " SF2                               " + CRLF
    _cQryDoc += " INNER JOIN "+ RetSqlName("SF3") +" SF3 ON" + RetSqlDel("SF3")   + CRLF
    _cQryDoc += "       AND F3_NFISCAL = F2_DOC                                 " + CRLF  
    _cQryDoc += "       AND F3_FILIAL = F2_FILIAL                               " + CRLF  
    _cQryDoc += "       AND F3_CLIENT = F2_CLIENTE                              " + CRLF
    _cQryDoc += "       AND F3_SERIE = F2_SERIE                                 " + CRLF   
    _cQryDoc += " INNER JOIN "+ RetSqlName("SA1") +" A1 ON" + RetSqlDel("A1")     + CRLF
    _cQryDoc += "       AND A1_COD = F2_CLIENTE                                 " + CRLF 
    _cQryDoc += "       AND A1_LOJA = F2_LOJA                                   " + CRLF   
    _cQryDoc += " WHERE                                                         " + CRLF
    _cQryDoc += " 	    F2_EMISSAO >= '"+Dtos(dDataZp)+"'                       " + CRLF // Data que o fonte entrou em producao - 20211230
    _cQryDoc += " 	    AND F3_CODRSEF IN ('100', 'S')                          " + CRLF // Nota foi transmitida
    //_cQryDoc += " 	    AND A1_ZAP = '2'                                        " + CRLF // Campo de bloqueio do envio whatsapp
    _cQryDoc += " 	    AND F2_X_ZAPDA = ''                                     " + CRLF // Nao foi enviada a menasgem
    _cQryDoc += " 	    AND F2_X_ZAPHO = ''                                     " + CRLF // Nao foi enviada a menasgem
    _cQryDoc += " 	    AND F2_X_ZAPOB = ''                                     " + CRLF // Nao foi enviada a menasgem
    _cQryDoc += " 	    AND SF2.D_E_L_E_T_ = ''                                 " + CRLF

    DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQryDoc), Self:_cAlias , .T. , .F.)

Return


/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Validacoes para o envio correto da mensagem 
@type   		Method	mValid
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			
@return			Logico			
*****************************************************************************************************/
Method mValid() Class ZAPLV 

    //---------------------------------------------------------------------------------
    //Abertura da tabela de log
    //---------------------------------------------------------------------------------
    DbSelectArea("ZZX")

    DbSelectArea('SF2')//Posiciona na NF
    SF2->(DbGoTo((Self:_cAlias)->SF2REC))

    DbSelectArea('SA1')  // Cliente
    SA1->(DbSetOrder(1)) // Filial + Código + Loja
    If !(SA1->(DbSeek(FWxFilial('SA1') + SF2->F2_CLIENTE + SF2->F2_LOJA)))
        Self:_cMsg :=   "Nao foi possivel localizar o cliente"  +CRLF+;
                        "Cliente cadastrado na SF2"             +CRLF+;
                        "Cliente:'"+SF2->F2_CLIENTE+"' "        +CRLF+;
                        "Loja:'"+SF2->F2_LOJA+"'"

        Return(.F.)
    EndIf 


    //--------------------------------------------------------------------------------------
    // Cliente nao possui os dados corretos para o envio
    //--------------------------------------------------------------------------------------
    If Empty((Self:_cAlias)->A1_DDD)  .OR. Empty((Self:_cAlias)->A1_TEL)
        Self:_cMsg :=   "Atualizar o cadastro de cliente!"          +CRLF+;
                        "Cliente:'"+(Self:_cAlias)->F2_CLIENTE+"' " +CRLF+;
                        "Loja:'"+(Self:_cAlias)->F2_LOJA+"'"

        ::mLockValid(.T.)

        ::mPrepReck("2")

        Return(.F.)
    EndIf 

    //---------------------------------------------------------------------------------
    // Forma de pagamento da nota 
    // Indice - E4_FILIAL, E4_CODIGO
    //---------------------------------------------------------------------------------
    Self:_cFormPg := AllTrim(Posicione("SE4", 1, xFilial("SE4")+SF2->F2_COND, "E4_FORMA"))
Return(.T.)


/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo para enviar todas as notas pelo whatsapp
@type   		Method	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			
@return			Nil 		
*****************************************************************************************************/
Method mLoop() Class ZAPLV 

Local aAreaWZ       := GetArea()
Local nTotal        := 0
Local nAtual        := 0
Local cMensagem     := ""
Local cMsgBol       := ""
Local cMsgOs        := ""
Local cMsgRPS       := ""
Local _cArqXml      := ""
Local _cArqBol      := ""
Local cPasta        := "\x_whats\"
Local cArqDanfe     := ""
Local _cOs          := ""
Local cNome         := ""
Local cDDD          := ""
Local cTelefone     := ""
Local _cNumBol      := ""
Local _cPrefx       := ""
Local _cClient      := ""
Local _cLoja        := ""
Local _cFil         := ""
Local _cSerBol      := ""
Local _cEmisBol     := ""
Private _cArqOs     := ""
Private _cPastaOs   := "\x_OS\" 
Private _cArqRps    := ""
Private _cPastRPS   := "\x_RPS\"
Private _cCodBarra  := ""

    Count To nTotal
    ProcRegua(nTotal)

    DBSelectArea(Self:_cAlias)
    (Self:_cAlias)->( DBGoTop() )
    While (Self:_cAlias)->( !Eof() )

        nAtual++
        Conout("Analisando NF " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")

        //---------------------------------------------------------------------------
        //Metodo para realizar validacoes dos registros
        //---------------------------------------------------------------------------
        If  ::mValid()
            //---------------------------------------------------------------------------
            //Metodo para criar diretorio do documento
            //---------------------------------------------------------------------------
            ::mPreparaDoc(cPasta, @cArqDanfe, @_cArqXml, @_cArqBol, @_cArqOs, _cPastaOs, @_cArqRps, _cPastRPS )
            //---------------------------------------------------------------------------
            //Metodo para criar a mensagem de envio
            //---------------------------------------------------------------------------
            ::mPrepMsg(@cNome, @cDDD, @cTelefone, @cMensagem, @cMsgBol, @cMsgOs, @cMsgRPS)
            //---------------------------------------------------------------------------
            //Metodo definir o tipo de relatorio - Danfe ou RPS
            //---------------------------------------------------------------------------
            ::mDefNfSerie(cPasta, _cArqXml, cArqDanfe, _cArqRps, _cPastRPS)
            //---------------------------------------------------------------------------
            //Metodo para rastrear a OS 
            //---------------------------------------------------------------------------
            ::mOS(_cOs)
            //---------------------------------------------------------------------------
            // Metodo para definir o boleto de envio
            //---------------------------------------------------------------------------
            ::mDefBol(@_cNumBol, @_cPrefx, @_cClient, @_cLoja, @_cFil, @_cSerBol, @_cEmisBol, cPasta, _cArqBol)
            //---------------------------------------------------------------------------
            //Metodo para enviar a mensagem no whatsap
            //---------------------------------------------------------------------------
            ::mEnvioMsg(cPasta, cArqDanfe, _cArqBol, cMensagem, cDDD, cTelefone, cMsgBol, , _cArqOs, _cPastaOs, cMsgOs, cMsgRPS, _cArqRps, _cPastRPS)
            //---------------------------------------------------------------------------
            //Metodo para zerar as variaveis
            //---------------------------------------------------------------------------
            ::mZerarVar()
        EndIf 

        (Self:_cAlias)->(DbSkip())

    EndDo
    
    ::mCloseArea()    

    RestArea(aAreaWZ)
    
Return 

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo que definir o fluxo seguir pela serie da nota fiscal 
@type   		Method	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			
@return			Nil 		
*****************************************************************************************************/
Method mDefNfSerie(cPasta, _cArqXml, cArqDanfe, _cArqRps, _cPastRPS) Class ZAPLV 

Local lXml := .F.

    //---------------------------------------------------------------------------
    //SERIE 1 SAIDA - DIFERENTE DE 1 SERVICOS
    //---------------------------------------------------------------------------
    If AllTrim((Self:_cAlias)->F2_SERIE) == "1" 
        //---------------------------------------------------------------------------
        //Metodo para criar o xml da nota
        //---------------------------------------------------------------------------
        lXml := ::mXML(Self:_cNota, AllTrim(Self:_cSerie), cPasta + _cArqXml+".xml", .F.)

        If lXml 
            //---------------------------------------------------------------------------
            //Metodo para gerar o Dnafe da nota
            //---------------------------------------------------------------------------
            ::mDanfe(Self:_cNota, Self:_cSerie, cPasta,  cArqDanfe)
        EndIf 
    Else
        //---------------------------------------------------------------------------
        //Metodo para alimentar os parametros do relatorio RPS
        //---------------------------------------------------------------------------
        ::mRelRPS(_cArqRps, _cPastRPS)
    EndIf  

Return 

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo para rastrear a OS e fazer o relatorio 
@type   		Method	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			
@return			Nil 		
*****************************************************************************************************/
Method mOS(_cOs) Class ZAPLV

Local _cOrc := ""
    //---------------------------------------------------------------------------
    // Metotdo para mapear a OS 
    //---------------------------------------------------------------------------
    If ::mTrackOs(@_cOs)

        If ExistBlock("IMPORD")  
            ExecBlock("IMPORD",.f.,.f.,{_cOs,'IMPORD',"S"}) // ExecBlock("IMPORD",.f.,.f.,{cNumOsv,'IMPORD',.t.})
        EndIf
        //---------------------------------------------------------------------------
        //Contagem para envio da os para o cliente
        //---------------------------------------------------------------------------
        Self:_nCntOS ++
    
    ElseIf ::Budget(@_cOrc)

        U_OrcWhatsapp(_cOrc)
        
        Self:_nCntOrc ++

    EndIf 

Return 

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo para rastrear o orcamento
@type   		Method	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		03/03/2022
@database		03/03/2022
@country		Brasil
@language		PT-BR
@obs			03/03/2022 - Controle de documentacao
@param			_cOrc, String, Alimentar o numero do orcamento
@return			Nil 		
*****************************************************************************************************/
Method Budget(_cOrc) Class ZAPLV

Local _cAliasOrc := GetNextAlias() 
Local _cSqlOrc   := ""

    _cSqlOrc  := "SELECT                                    " +CRLF 
    _cSqlOrc  += " VS1_NUMORC                               " +CRLF 
    _cSqlOrc  += " FROM                                     " +CRLF 
    _cSqlOrc  += " 	" + RetSQLName("VS1") + " VS1 " 
    _cSqlOrc  += " WHERE                                    " +CRLF 
    _cSqlOrc  += " VS1_NUMNFI = '"+SF2->F2_DOC+"'           " +CRLF 
    _cSqlOrc  += " AND VS1_FILIAL = '"+SF2->F2_FILIAL+"'    " +CRLF 
    _cSqlOrc  += " AND D_E_L_E_T_ = ''                      " +CRLF 

    DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cSqlOrc), _cAliasOrc , .T. , .F.)

    If !Empty((_cAliasOrc)->VS1_NUMORC )
        _cOrc := (_cAliasOrc)->VS1_NUMORC 
        Return(.T.)
    EndIf 

    (_cAliasOrc)->(DbCloseArea())
    
Return(.F.)

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo para gerar o boleto 
@type   		Method	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			
@return			Nil 		
*****************************************************************************************************/
Method mDefBol(_cNumBol, _cPrefx, _cClient, _cLoja, _cFil, _cSerBol, _cEmisBol,  cPasta, _cArqBol) Class ZAPLV

    //---------------------------------------------------------------------------
    // Geracao de boleto somente tipo BOL
    //---------------------------------------------------------------------------
    If Self:_cFormPg == "BOL"
        //-----------------------------------------------------
        // Metodo para preparar variaveis 
        //-----------------------------------------------------
        ::mPrpBol(@_cNumBol, @_cPrefx, @_cClient, @_cLoja, @_cFil, @_cSerBol, @_cEmisBol)
        //-----------------------------------------------------
        // Metodo para gerar a query do boleto 
        //-----------------------------------------------------
        If ::mBolQr(_cNumBol, _cPrefx, _cClient, _cLoja, _cFil, _cSerBol, _cEmisBol)
            //---------------------------------------------------------------------------
            //Metodo que defini o tipo do boleto para envia-lo 
            //---------------------------------------------------------------------------
            ::mChoiceBol(cPasta, _cArqBol)
        EndIf
    EndIf 
    
Return 

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Envia a mensagem no whatsapp
@type   		Method	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			cPasta      , String, Nome da pasta
@param          cArqDanfe   , String, Nome do arquivo Danfe/OS
@param          _cArqBol    , String, Nome do arquivo Boleto
@param          cMensagem   , String, Mensagem de envio Danfe
@param          cDDD        , String, Numero DDD
@param          cTelefone   , String, Numero Telefone
@param          cMsgBol     , String, Mensagem de envio Boleto
@param          _cEnvOrc    , String, Numero do orcamento 
@param          _cArqOs     , String , Nome da pasta OS
@param          _cPastaOs   , String , Nome do arquivo OS 
@param          cMsgOs      , String , Mensagem OS
@param          cMsgRPS     , String , Mensagem RPS 
@param          _cArqRps    , String , Nome do arquivo RPS
@param          _cPastRPS   , String , Noma da pasta RPS 
@return			Nil 		
*****************************************************************************************************/
Method mEnvioMsg(cPasta, cArqDanfe, _cArqBol, cMensagem,  cDDD, cTelefone, cMsgBol, _cEnvOrc, _cArqOs, _cPastaOs, cMsgOs, cMsgRPS, _cArqRps, _cPastRPS) Class ZAPLV 

Default cPasta      := ""
Default cArqDanfe   := ""
Default _cArqBol    := ""
Default cMensagem   := ""
Default cDDD        := ""
Default cTelefone   := ""
Default cMsgBol     := ""
Default _cEnvOrc    := ""
Default _cOs        := ""
Default _cPastaOs   := ""
Default cMsgOs      := ""
Default cMsgRPS     := ""
Default _cArqRps    := ""
Default _cPastRPS   := ""
    //-----------------------------------------------------
    //Faz o envio da nota fiscal de saida 
    //-----------------------------------------------------
    If File(cPasta + cArqDanfe+".pdf") 
        Self:aZap  := u_zZapSend("55" + cDDD + cTelefone    , cMensagem, cPasta + cArqDanfe+".pdf")
        Sleep( 1000 ) // thread corrente deixe de ser executada por 1 Segundo
        //Self:aZap  := u_zZapSend("55" +  "61"+ "982649904"  , cMensagem, cPasta + cArqDanfe+".pdf") // Numero Lucas Rocha - Analisata de sistemas
        //u_zZapSend("55" +  "61"+ "99136991"   , cMensagem, cPasta + cArqDanfe+".pdf") // Numero Anderson - Gerente T.I
        FErase(cPasta + cArqDanfe +".pdf")
        FErase(cPasta + cArqDanfe +".xml")
        
        Self:_lEnvio := Self:aZap[1]

        Sleep( 1000 ) // thread corrente deixe de ser executada por 1 Segundo
    EndIf 

    //-----------------------------------------------------
    //Envio do RPS - nota de servicos
    //-----------------------------------------------------
    If File(_cPastRPS + _cArqRps+".pdf")
        Self:aZap  := u_zZapSend("55" + cDDD + cTelefone  , cMsgOs, _cPastaOs + _cArqOs+".pdf")
        //Self:aZap  :=u_zZapSend("55" +  "61"+ "982649904", cMsgRPS, _cPastRPS + _cArqRps+".pdf")
        //u_zZapSend("55" +  "61"+ "99136991" , cMsgRPS, _cPastRPS + _cArqRps+".pdf")
        FErase(_cPastRPS + _cArqRps +".pdf")

        Self:_lEnvio := Self:aZap[1]
        Sleep( 1000 ) // thread corrente deixe de ser executada por 1 Segundo
    EndIf 

    //-----------------------------------------------------
    //Envio do boleto 
    //-----------------------------------------------------
    If Self:_nCntBol > 0 
        If File(cPasta + _cArqBol+".pdf")
            //-----------------------------------------------------
            //Metodo para enviar o boleto por email
            //-----------------------------------------------------
            ::mMailBol(cPasta , _cArqBol)
            Self:aZap  := u_zZapSend("55" + cDDD + cTelefone  , cMsgBol, cPasta + _cArqBol+".pdf")
            //u_zZapSend("55" +  "61"+ "982649904", cMsgBol, cPasta + _cArqBol+".pdf")
            //u_zZapSend("55" +  "61"+ "99136991" , cMsgBol, cPasta + _cArqBol+".pdf")


            FErase(cPasta + _cArqBol +".pdf")
            Self:_lEnvio := Self:aZap[1]
        EndIf 
        Sleep( 1000 ) // thread corrente deixe de ser executada por 1 Segundo
    EndIf 

    //-----------------------------------------------------
    //Envio do OS
    //-----------------------------------------------------
    If Self:_nCntOS > 0 
        If File(_cPastaOs + _cArqOs+".pdf")
            Self:aZap  := u_zZapSend("55" + cDDD + cTelefone  , cMsgOs, _cPastaOs + _cArqOs+".pdf")
           //Self:aZap  := u_zZapSend("55" +  "61"+ "982649904", cMsgOs, _cPastaOs + _cArqOs+".pdf")
            //u_zZapSend("55" +  "61"+ "99136991" , cMsgOs, _cPastaOs + _cArqOs+".pdf")
            FErase(_cPastaOs + _cArqOs +".pdf")
            Self:_lEnvio := Self:aZap[1]
        EndIf 
        Sleep( 1000 ) // thread corrente deixe de ser executada por 1 Segundo
    EndIf

    //-----------------------------------------------------
    //Envio do Orcamentno
    //-----------------------------------------------------
    If Self:_nCntOrc > 0 
        If File(_cPastaOs + _cArqOs+".pdf")
            Self:aZap  := u_zZapSend("55" + cDDD + cTelefone  , "Orçamento:", _cPastaOs + _cArqOs+".pdf")
            u_zZapSend("55" +  "61"+ "982649904", "Orçamento:", _cPastaOs + _cArqOs+".pdf")
            //u_zZapSend("55" +  "61"+ "99136991" , cMsgOs, _cPastaOs + _cArqOs+".pdf")
            FErase(_cPastaOs + _cArqOs +".pdf")
            Self:_lEnvio := Self:aZap[1]
        EndIf 
        Sleep( 1000 ) // thread corrente deixe de ser executada por 1 Segundo
    EndIf

    //---------------------------------------------------------------------------
    //ReckLock no campo de envio 
    //---------------------------------------------------------------------------
    ::mReckLock(Self:_lEnvio, _cEnvOrc)


    Sleep( 1000 ) // thread corrente deixe de ser executada por 1 Segundo

Return

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Grava na tabela SF2 o envio da mensagem
@type   		Method	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			lRecb   , Logico, Retorno do envio da mensagem 
@param          _cEnvOrc, String, Numero da OS
@return			Nil 		
*****************************************************************************************************/
Method mReckLock(lRecb, _cEnvOrc) Class ZAPLV 

Local aArea      := GetArea()
Default lRecb    := .F.
Default _cEnvOrc := ""


    //---------------------------------------------------------------------------
    //_cEnvOrc == 1 Tipo OS 
    //---------------------------------------------------------------------------
    If _cEnvOrc == "1" .AND. lRecb
        Self:_cMsg :=   "Os enviada com sucesso!" +CRLF+;
                        "Cliente:'"+SA1->A1_COD+"'"  
        Self:_cOc := VO1->VO1_NUMOSV
        ::mPrepReck("4")
        Return 
    EndIf  

    //---------------------------------------------------------------------------
    //Tratando o erro na os 
    //---------------------------------------------------------------------------
    If _cEnvOrc == "1" .AND. !lRecb
        Self:_cMsg :=   "Os enviada com sucesso!" +CRLF+;
                        "Cliente:'"+SA1->A1_COD+"'"  
        Self:_cOc := VO1->VO1_NUMOSV
        ::mPrepReck("7")
        Return 
    EndIf 
    //------------------------------------------------------------
    //RecLock na tabela SF2 - NF de saida
    //------------------------------------------------------------
    If ! lRecb

        RecLock("SF2", .F.)
            SF2->F2_X_ZAPOB := AllTrim(Self:aZap[2])
        SF2->(MsUnlock())       

        Self:_cMsg :=  "Erro ao enviar a Danfe!"         +CRLF+;
                        "Consulte o campo F2_X_ZAPOB"       +CRLF+;
                        "Cliente:'"+SF2->F2_CLIENTE+"' "    +CRLF+;
                        "Loja:'"+SA1->A1_LOJA+"'"  

        ::mPrepReck("3")

    Else

        RecLock("SF2", .F.)
            SF2->F2_X_ZAPDA := Date()
            SF2->F2_X_ZAPHO := Time()
            SF2->F2_X_ZAPOB := AllTrim(Self:aZap[2])
        SF2->(MsUnlock())

        Self:_cMsg :=   "Danfe enviada com sucesso!" +CRLF+;
                        "Cliente:'"+SF2->F2_CLIENTE+"'"   

        ::mPrepReck("1")

        //---------------------------------------------------------------------------------
        //RecLock na tabela SE1 - Contas a Receber 
        //---------------------------------------------------------------------------------
        If Self:_nCntBol > 0 

            DbSelectArea(Self:_cAliasBol)
            (Self:_cAliasBol)->(DbGoTop())
            While (Self:_cAliasBol)->(!Eof())
             
                DbSelectArea("SE1")
                SE1->(DbSetOrder(1))// E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO, R_E_C_N_O_, D_E_L_E_T_
                If SE1->(DbSeek( xFilial("SE1") + (Self:_cAliasBol)->E1_PREFIXO + (Self:_cAliasBol)->E1_NUM+ (Self:_cAliasBol)->E1_PARCELA  + (Self:_cAliasBol)->E1_TIPO  ))

                    RecLock("SE1", .F.)
                        SE1->E1_ZBOLENV := Date()
                        SE1->E1_ZBOLHRS := Time()
                        SE1->E1_ZBOLRES := AllTrim(Self:aZap[2])
                    SE1->(MsUnlock())

                    Self:_cMsg :=   "Boleto enviado com sucesso!" +CRLF+;
                                    "Cliente:'"+SF2->F2_CLIENTE+"'"   
                EndIf 

                (Self:_cAliasBol)->(DbSkip())

            EndDo 

                (Self:_cAliasBol)->(DbCloseArea())

            ::mPrepReck("6")

        EndIf 

        If Self:_nCntOS > 0 
            Self:_cMsg :=   "Os enviada com sucesso!" +CRLF+;
                            "Cliente:'"+SA1->A1_COD+"'"  
            Self:_cOc := VO1->VO1_NUMOSV
            ::mPrepReck("4")
        EndIf 

    EndIf 

    RestArea(aArea)

Return 

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo para enviar o boleto
@type   		Method	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		04/03/2022
@database		04/03/2022
@country		Brasil
@language		PT-BR
@obs			04/03/2022 - Controle de documentacao
@param			cPasta   , String, Nome da pasta
@param          _cArqBol , String, Nome do arquivo
@return			Nil 		
*****************************************************************************************************/
Method mMailBol(cPasta, _cArqBol) Class ZAPLV

Local _cHtml := ""
Local _cMail := ""
Local _cCgc := ""

    If Empty(SA1->A1_EMAIL)
        Self:_cMsg := "Email em branco no cadastro de cliente"
        ::mPrepReck("8")
        Return
    ElseIf Empty(_cCodBarra)
        Return 
    Else 
        _cMail := AllTrim(SA1->A1_EMAIL)
    EndIf 

	_cCgc  := subs(transform(SA1->A1_CGC,PicPes(RetPessoa(SA1->A1_CGC))),1,at("%",transform(SA1->A1_CGC,PicPes(RetPessoa(SA1->A1_CGC))))-1)
	_cCgc  := _cCgc + space(18-len(_cCgc))

    ::mPrepHtml(@_cHtml, _cCgc)

    //--------------------------------------------------------------------------------------
    //Funcao para enviar o boleto por email
    //--------------------------------------------------------------------------------------
    If !(U_LucasRochaSNDEML(_cMail, "LucasRocha - Boleto", _cHtml , cPasta + _cArqBol +".pdf", .F., ,,, ))
        Self:_cMsg := "Falha ao enviar o email"
        ::mPrepReck("8")
    Else 
        Self:_cMsg := "Email envaido com sucesso!"
        ::mPrepReck("9")
    EndIf 

Return

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo para prepara o html do email
@type   		Method	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		04/03/2022
@database		04/03/2022
@country		Brasil
@language		PT-BR
@obs			04/03/2022 - Controle de documentacao
@param			_cHtml   , String, nome do arquivo
@return			Nil 		
*****************************************************************************************************/
Method mPrepHtml(_cHtml, _cCgc) Class ZAPLV 

    (Self:_cAliasBol)->(DbGoTop())

_cHtml := '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
_cHtml += '<html xmlns="http://www.w3.org/1999/xhtml">
_cHtml += '<head>
_cHtml += '<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
_cHtml += '<meta name="viewport" content="width=device-width, initial-scale=1">
_cHtml += '<link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
_cHtml += '<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
_cHtml += '<title>Boleto</title>
_cHtml += '  <style type="text/css"> 
_cHtml += '	body {background-color: rgb(211,211,211);} 
_cHtml += '	.hr1 {
_cHtml += '	  border: 0;
_cHtml += '	  border-top: 18px solid;
_cHtml += '	  color: rgb(0,128,0);
_cHtml += '	  margin-top:5px; 
_cHtml += '	  margin-right: -15px;
_cHtml += '	  margin-left: -15px; 
_cHtml += '	}
_cHtml += '	.hr2 {
_cHtml += '	  border: 0;
_cHtml += '	  border-top: 13px solid;
_cHtml += '	  color: rgb(255,215,0);
_cHtml += '	  margin-top:-10px; 
_cHtml += '	  margin-right: -15px;
_cHtml += '	  margin-left: -15px; 
_cHtml += '	}
_cHtml += '	.style1 {
_cHtml += '		font-family: times new roman;
_cHtml += '		font-size: 10pt;
_cHtml += '	} 
_cHtml += '	.style2 {
_cHtml += '		font-family: times new roman;
_cHtml += '		font-size: 18pt;
_cHtml += '		margin-top: 20px; 
_cHtml += '		margin-left: 30px; 
_cHtml += '	} 
_cHtml += '	.style3 {
_cHtml += '		font-family: times new roman;
_cHtml += '		font-size: 10pt;
_cHtml += '		color: rgb(169,169,169); 
_cHtml += '		margin-left: 30px; 
_cHtml += '	} 
_cHtml += '	.style4 {
_cHtml += '		font-size: 14pt; 
_cHtml += '		font-family: times new roman;
_cHtml += '		font-weight: bold;
_cHtml += '		margin-left: 20px; 
_cHtml += '	} 
_cHtml += '	.style5 {
_cHtml += '		font-size: 11pt; 
_cHtml += '		font-family: times new roman;
_cHtml += '		margin-left: 20px; 	
_cHtml += '	} 
_cHtml += '	.style6 {
_cHtml += '		font-size: 12pt; 
_cHtml += '		font-family: times new roman;
_cHtml += '	} 
_cHtml += '	.style7 {
_cHtml += '		font-size: 12pt; 
_cHtml += '		font-family: times new roman;
_cHtml += '	}
_cHtml += '	.style8 {
_cHtml += '		font-size: 11pt; 
_cHtml += '		font-family: times new roman;
_cHtml += '		margin-left: 50px; 	
_cHtml += '	} 
_cHtml += '	.style9 {
_cHtml += '		font-size: 11pt; 
_cHtml += '		font-family: times new roman;
_cHtml += '		margin-left: 750px; 
_cHtml += '		font-weight: bold;		
_cHtml += '	} 
_cHtml += '	.logo{
_cHtml += '		background-color: rgb(240, 240, 240); 
_cHtml += '		margin-top:25px; 
_cHtml += '		margin-right: 10px; 
_cHtml += '		float: right;
_cHtml += '	}
_cHtml += '  </style>
_cHtml += '</head>
_cHtml += '<body>
_cHtml += '<center>
_cHtml += '<table style="background-color: rgb(240, 240, 240); width: 800px; text-align: left; margin-left: auto; margin-right: auto;"  border="0" cellpadding="8">
_cHtml += '  <tbody>
_cHtml += '    <tr>
_cHtml += '		<td>
_cHtml += '			<div class="style3">Concessionário Autorizado John Deere</div>	
_cHtml += '			<!--<div class="style2">LucasRocha</div> -->
_cHtml += '		</td>
_cHtml += '		<td>
_cHtml += '			<center>
_cHtml += '			<img src="https://fluig.LucasRocha.com.br/volume/stream/Rmx1aWc=/P3Q9MSZ2b2w9RGVmYXVsdCZpZD01MDgmdmVyPTEwMDAmZmlsZT1sb2dvX2pkLnBuZyZjcmM9MzUxNzc1MTM5OCZzaXplPTAuMDA5MjI5JnVJZD0xMCZmU0lkPTEmdVNJZD0xJmQ9ZmFsc2UmdGtuPSZwdWJsaWNVcmw9dHJ1ZQ==.png" 
_cHtml += '			style="width: 300px;">
_cHtml += '			</center>
_cHtml += '		</td>
_cHtml += '    </tr>
_cHtml += '	
_cHtml += '	<tr>
_cHtml += '	  <td colspan="2">
_cHtml += '		  <img src="https://fluig.LucasRocha.com.br/volume/stream/Rmx1aWc=/P3Q9MSZ2b2w9RGVmYXVsdCZpZD01MDQmdmVyPTEwMDAmZmlsZT1saW5oYS5wbmcmY3JjPTU4NjE3MDM5MiZzaXplPTMuMDZFLTQmdUlkPTEwJmZTSWQ9MSZ1U0lkPTEmZD1mYWxzZSZ0a249JnB1YmxpY1VybD10cnVl.png"> 
_cHtml += '	  </td>
_cHtml += '	</tr>
_cHtml += '	<tr>
_cHtml += '	  <td colspan="2">
_cHtml += '		<div class="style4">Sua fatura chegou! :)</div> 
_cHtml += '		<br>
_cHtml += '		<div class="style5">
_cHtml += '			Este e-mail é um resumo da sua fatura.<br>
_cHtml += '			Para visualizar a versão completa, baixe o anexo ou entre em contato conosco. 
_cHtml += '		</div> 
_cHtml += '	  </td>
_cHtml += '	</tr>
_cHtml += '	
_cHtml += '    <tr>
_cHtml += '      <td colspan="2">
_cHtml += '		<div style="font-size: 12pt; font-family: times new roman; width: 830px; height: 50px; background-color: rgb(211,211,211); margin-left: 50px; margin-right: 50px" >
_cHtml += '			</br>
_cHtml += '			<div>Cliente: '+Capital(AllTrim(SA1->A1_NOME))+' </div>'
_cHtml += '			</br>
_cHtml += '		</div>	
_cHtml += '      </td>
_cHtml += '	</tr> 	
_cHtml += '	<tr>
_cHtml += '      <td colspan="1">
_cHtml += '		<div style="font-size: 12pt; font-family: times new roman; width: 400px; height: 50px; background-color: rgb(211,211,211); margin-left: 50px;" >
_cHtml += '			</br>
_cHtml += '			<div>CNPJ: '+AllTrim(_cCgc)+' </div>'
_cHtml += '			</br>
_cHtml += '		</div>
_cHtml += '      </td>
_cHtml += '	  <td colspan="1">
_cHtml += '	  	<div style="font-size: 12pt; font-family: times new roman;width: 400px; height: 50px; background-color: rgb(211,211,211); margin-right: 50px">
_cHtml += '			</br>
_cHtml += '			<div> Nº da Fatura: '+AllTrim(SF2->F2_DOC)+'  Parc: '+AllTrim((Self:_cAliasBol)->E1_PARCELA)+' </div>'
_cHtml += '			</br>			
_cHtml += '		</div>
_cHtml += '	  </td>
_cHtml += '    </tr>
_cHtml += '	<tr>
_cHtml += '      <td>
_cHtml += '		<div style="font-size: 12pt; font-family: times new roman; width: 400px; height: 50px; background-color: rgb(255,222,0); margin-left: 50px;" >
_cHtml += '			</br>
_cHtml += '			<div>Vencimento:<b> '+Dtoc(Stod((Self:_cAliasBol)->E1_VENCTO))+' </b></div>
_cHtml += '			</br>
_cHtml += '		</div>
_cHtml += '      </td>
_cHtml += '	  <td >
_cHtml += '		<div style="font-size: 12pt; font-family: times new roman;width: 400px; height: 50px; background-color: rgb(255,222,0); margin-right: 50px" >
_cHtml += '			</br>
_cHtml += '			<div> Valor:<b> R$ '+Transform((Self:_cAliasBol)->E1_VALOR,"@E 99999,999.99")+' </b></div>
_cHtml += '			</br>			
_cHtml += '		</div> 
_cHtml += '	  </td>
_cHtml += '    </tr>	
_cHtml += '	<tr>
_cHtml += '      <td colspan="2">
_cHtml += '		<div class="style8">Utilize o número do código de barras abaixo para realizar o pagamento.</div>
_cHtml += '		
_cHtml += '		<div class="style6" style="width: 830px; height: 50px; background-color: rgb(255,222,0); margin-left: 50px; margin-right: 50px" >
_cHtml += '			</br>
_cHtml += '			<div>Código de barras:<b> '+AllTrim(_cCodBarra)+' </b></div>
_cHtml += '			</br>
_cHtml += '		</div>		
_cHtml += '      </td>
_cHtml += '	</tr> 
_cHtml += '	<tr>
_cHtml += '	  <td colspan="2">
_cHtml += '		<br>
_cHtml += '		<br>
_cHtml += '		<br>
_cHtml += '		<br>
_cHtml += '		<div class="style5" style="width: 830px; ">
_cHtml += '			Entre em contato com a LucasRocha por meio de nossos canais de atendimento:<a href="http://www.LucasRocha.com.br/"> Clique aqui! </a>
_cHtml += '		</div> 
_cHtml += '		<br>
_cHtml += '		<br>
_cHtml += '	  </td>
_cHtml += '	</tr>
_cHtml += '	<tr>
_cHtml += '	  
_cHtml += '	  <td colspan="2">
_cHtml += '	  <center>
_cHtml += '		<em><span style="width: 350px; font-size: 11pt; font-family: times new roman; font-weight: bold;">
_cHtml += '		Developed by Ti | LucasRocha</span></em>
_cHtml += '	  </center>
_cHtml += '	  </td>
_cHtml += '	</tr> 
_cHtml += '  </tbody>
_cHtml += '</table>
_cHtml += '</center>
_cHtml += '</body>
_cHtml += '</html>


Return 
/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo responsavel por definir parametros para geracao na tabela ZZX 
@type   		Method 
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			_cNivl:
                        1 - Envio ok Danfe 
                        2 - Cliente com dados incompletos JOB
                        3 - Erro ao integrar com api
                        4 - Envio ok OS 
                        5 - Cliente com dados incompletos OS 
                        6 - Envio ok Boleto 
                        7 - Erro na OS 
                        8 - Email do cliente incorreto
                        9 - Envio Boleto por email
@return		    Nil 				
*****************************************************************************************************/
Method mPrepReck(_cNivl) Class ZAPLV 

Default _cNivl := ""

    Do Case 
        Case _cNivl == "1"
            ::mTreatment(SF2->F2_CLIENTE, SF2->F2_LOJA, "1", Self:_cMsg, SF2->F2_DOC, SF2->F2_SERIE, SF2->F2_FILIAL, "NF") 
        Case _cNivl == "2"
            ::mTreatment((Self:_cAlias)->F2_CLIENTE, (Self:_cAlias)->F2_LOJA, "2", Self:_cMsg, (Self:_cAlias)->F2_DOC, (Self:_cAlias)->F2_SERIE, SF2->F2_FILIAL, "NF" )  
        Case _cNivl == "3"
            ::mTreatment(SF2->F2_CLIENTE, SF2->F2_LOJA, "3", Self:_cMsg, SF2->F2_DOC, SF2->F2_SERIE, SF2->F2_FILIAL) 
        Case _cNivl == "4"
            ::mTreatment(SA1->A1_COD, SA1->A1_LOJA, "1", Self:_cMsg , Self:_cOc , "" , cFilAnt, "OS")
        Case _cNivl == "5"
            ::mTreatment(SA1->A1_COD, SA1->A1_LOJA, "2", Self:_cMsg , Self:_cOc , "" , xFilial("VO1"), "OS")
        Case _cNivl == "6"
            ::mTreatment(SF2->F2_CLIENTE, SF2->F2_LOJA, "1", Self:_cMsg, (Self:_cAlias)->F2_DOC, (Self:_cAlias)->F2_SERIE, (Self:_cAlias)->F2_FILIAL, "BOL")
        Case _cNivl == "7"
            ::mTreatment(SA1->A1_COD, SA1->A1_LOJA, "1", Self:_cMsg, Self:_cOc   , "", cFilAnt, "OS")
        Case _cNivl == "8"
            ::mTreatment((Self:_cAlias)->F2_CLIENTE, (Self:_cAlias)->F2_LOJA, "2", Self:_cMsg, (Self:_cAlias)->F2_DOC, (Self:_cAlias)->F2_SERIE, SF2->F2_FILIAL, "BOL")    
        Case _cNivl == "9"
            ::mTreatment((Self:_cAlias)->F2_CLIENTE, (Self:_cAlias)->F2_LOJA, "1", Self:_cMsg, (Self:_cAlias)->F2_DOC, (Self:_cAlias)->F2_SERIE, SF2->F2_FILIAL, "BOL")        
    EndCase 

Return 

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Troca de empresa e cria o nome do documento XML/PDF
@type   		Method 
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			cPasta      , String, Nome da pasta 
@param			cArqDanfe   , String, Nome do arquivo Danfe
@param			_cArqXml    , String, Nome do arquivo XML 
@param			_cArqBol    , String, Nome do arquivo Boleto 
@param			_cArqOs     , String, Nome do arquivo Os
@param			_cPastaOs   , String, Nome da pasta da Os
@return			Nil			
*****************************************************************************************************/
Method mPreparaDoc(cPasta, cArqDanfe,_cArqXml, _cArqBol, _cArqOs, _cPastaOs, _cArqRps, _cPastRPS ) Class ZAPLV 


    //--------------------------------------------------------------------------------------
    //Se a filial for diferente, troca a empresa na memória
    //--------------------------------------------------------------------------------------
    If cFilAnt != (Self:_cAlias)->F2_FILIAL
        cFilAnt := (Self:_cAlias)->F2_FILIAL
        cNumEmp := Alltrim(cEmpAnt) + AllTrim(cFilAnt)
        OpenFile(cNumEmp)
    EndIf

    Self:_cNota  := (Self:_cAlias)->F2_DOC
    Self:_cSerie := (Self:_cAlias)->F2_SERIE

    //----------------------------------------------------------------------------
    //Define o nome do arquivo da danfe e boleto
    //----------------------------------------------------------------------------
    cArqDanfe := "danfe_" + Alltrim((Self:_cAlias)->F2_FILIAL)+Alltrim((Self:_cAlias)->F2_DOC)+Alltrim((Self:_cAlias)->F2_SERIE) + StrTran( Time() , ":" , "" )
    _cArqXml  := "danfe_" + Alltrim((Self:_cAlias)->F2_FILIAL)+Alltrim((Self:_cAlias)->F2_DOC)+Alltrim((Self:_cAlias)->F2_SERIE) + StrTran( Time() , ":" , "" )
    _cArqBol  := "Bol_"   + Alltrim((Self:_cAlias)->F2_FILIAL)+Alltrim((Self:_cAlias)->F2_DOC)+Alltrim((Self:_cAlias)->F2_SERIE) + StrTran( Time() , ":" , "" )
    _cArqOs   := "OS_"    + Alltrim((Self:_cAlias)->F2_FILIAL)+Alltrim((Self:_cAlias)->F2_DOC)+Alltrim((Self:_cAlias)->F2_SERIE) + StrTran( Time() , ":" , "" )
    _cArqRps  := "RPS_"   + Alltrim((Self:_cAlias)->F2_FILIAL)+Alltrim((Self:_cAlias)->F2_DOC)+Alltrim((Self:_cAlias)->F2_SERIE) + StrTran( Time() , ":" , "" )
    //---------------------------------------------------------------------------
    //Se o arquivo danfe existir, faz a exclusão dele
    //---------------------------------------------------------------------------
    If File(cPasta + cArqDanfe+".pdf") .OR. File(cPasta + _cArqXml + ".xml") .OR. File(cPasta + _cArqBol+".pdf") 
        FErase(cPasta + cArqDanfe   + ".pdf")
        FErase(cPasta + _cArqBol    + ".pdf")
        FErase(cPasta + _cArqOs     + ".pdf")
        FErase(cPasta + _cArqXml    + ".xml")
    EndIf

    //---------------------------------------------------------------------------
    //Se o arquivo da OS existir, faz a exclusão dele
    //---------------------------------------------------------------------------
    If File(_cPastaOs + _cArqOs+".pdf") 
        FErase(_cPastaOs + _cArqOs   + ".pdf")
    EndIf

    //---------------------------------------------------------------------------
    //Se o arquivo RPS existir, faz a exclusao
    //---------------------------------------------------------------------------
    If File(_cPastRPS + _cArqRps+".pdf") 
        FErase(_cPastRPS + _cArqRps   + ".pdf")
    EndIf

Return

/**************************************************************************************************
{Protheus.doc} mPrepMsg
@description	Prepara a mensagem de envio
@type   		Method	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			cNome       , String, Nome do cliente
@param			cDDD        , String, Numero DDD
@param			cTelefone   , String, Numero do telefone
@param			cMensagem   , String, Descricao da mensagem Danfe
@param			cMsgBol     , String, Descricao da mensagem Boleto 
@return			Nil 			
*****************************************************************************************************/
Method mPrepMsg(cNome, cDDD, cTelefone, cMensagem, cMsgBol, cMsgOs, cMsgRPS) Class ZAPLV 

Local _cLinkSfz   := "http://www.nfe.fazenda.gov.br/portal"
Local cFolha      := "\uD83D\uDCC4"
Local dAno        := YEAR(DATE())

    //------------------------------------------------------------------
    //Se tiver o contato, usa ele, do contrário, usa o nome reduzido
    //------------------------------------------------------------------
    If !Empty(SA1->A1_CONTATO)
        cNome := Alltrim(SA1->A1_CONTATO)
    Else
        cNome := Alltrim(SA1->A1_NREDUZ)
    EndIf

    cNome := Capital(cNome)

    //--------------------------------------------------------------------------------------------------
    //Pega o DDD, e se o usuário ter digitado 3 caracteres, retira o primeiro, por exemplo, 014 -> 14
    //--------------------------------------------------------------------------------------------------
    cDDD := Alltrim(SA1->A1_DDD)
    If Len(cDDD) == 3
        cDDD := SubStr(cDDD, 2)
    EndIf

    cTelefone := Alltrim(SA1->A1_TEL)

    //---------------------------------------------------------------
    //Monta a mensagem que será enviada ao cliente na Danfe
    //---------------------------------------------------------------
    cMensagem := '<b>'+'Olá ' + cNome + '</b>, ' + '<br>' + CRLF
    cMensagem += '<br>' + CRLF
    cMensagem += 'Sua Nota Fiscal Eletrônica Nacional foi gerada.'  + cFolha + '<br>' + CRLF
    cMensagem += '<br>' + CRLF
    cMensagem += 'Número: '+Self:_cNota+ '<br>' + CRLF 
    cMensagem += 'Para verificar a autorização da SEFAZ referente à nota acima mencionada, acesse o site: '+_cLinkSfz+ '<br>' + CRLF    
    cMensagem += 'Chave de acesso: '+AllTrim(SF2->F2_CHVNFE)+ '<br>' + CRLF 
    cMensagem += '<br>' + CRLF
    cMensagem += 'Esta mensagem foi enviada automaticamente pelo Sistema de Nota Fiscal Eletrônica (NF-e) da LucasRocha '+ '<br>' + CRLF 
    cMensagem += '<br>' + CRLF
    cMensagem += 'Caso tenha alguma dúvida, é só contatar a nossa equipe:'+ '<br>' + CRLF 
    cMensagem += 'financeiro@LucasRocha.com.br'+ '<br>' + CRLF 
    cMensagem += '(61)3030-3666'+ '<br>' + CRLF 
    cMensagem += '<br>' + CRLF
    cMensagem += 'Abraços da equipe LucasRocha!!!'+ '<br>' + CRLF 
    cMensagem += "http://www.LucasRocha.com.br"+ '<br>' + CRLF 
    cMensagem += '<br>' + CRLF
    cMensagem += 'Copyright ' + cValToChar(dAno) + ' - LucasRocha. Todos os direitos reservados.'


    //---------------------------------------------------------------
    // Mensagem que será enviada ao cliente no boleto
    //---------------------------------------------------------------
    cMsgBol := 'Seu boleto foi gerado: '  + cFolha + '<br>' 

    //---------------------------------------------------------------
    // Mensagem que será enviada ao cliente na OS
    //---------------------------------------------------------------
    cMsgOs  := 'Referente a OS: '  + cFolha + '<br>' 

    //---------------------------------------------------------------
    // Mensagem que será enviada ao cliente - RPS
    //---------------------------------------------------------------
    cMsgRPS := '<b>'+'Olá ' + cNome + '</b>, ' + '<br>' + CRLF
    cMsgRPS += '<br>' + CRLF
    cMsgRPS += 'Sua Nota Fiscal Eletrônica foi gerada.'  + cFolha + '<br>' + CRLF
    cMsgRPS += '<br>' + CRLF
    cMsgRPS += 'Número do RPS : '+ (Self:_cAlias)->F2_NFELETR + 'Série: '+ (Self:_cAlias)->F2_SERIE + '<br>' + CRLF 
    cMsgRPS += '<br>' + CRLF
    cMsgRPS += 'Esta mensagem foi enviada automaticamente pelo Sistema de Nota Fiscal Eletrônica (NF-e) da LucasRocha '+ '<br>' + CRLF 
    cMsgRPS += 'Caso tenha alguma dúvida, é só contatar a nossa equipe:'+ '<br>' + CRLF 
    cMsgRPS += 'financeiro@LucasRocha.com.br'+ '<br>' + CRLF 
    cMsgRPS += '(61)3030-3666'+ '<br>' + CRLF 
    cMsgRPS += '<br>' + CRLF
    cMsgRPS += 'Abraços da equipe LucasRocha!!!'+ '<br>' + CRLF 
    cMsgRPS += "http://www.LucasRocha.com.br"+ '<br>' + CRLF 
    cMsgRPS += '<br>' + CRLF
    cMsgRPS += 'Copyright ' + cValToChar(dAno) + ' - LucasRocha. Todos os direitos reservados.'

Return 

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo para gravar os logs de envio de mensagem na tabela ZZX 
@type   		Method 
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			_cCodCli, String, Codigo do cliente
@param			_cLoja  , String, Codigo da loja 
@param			_cStatus, String, Status do envio da mensagem
@param			_cDescri, String, Descricao da mensagem
@param			_cDoc   , String, Numero da nota ou OS 
@param			_cSerie , String, Seire da nota
@param			_cFilEnv, String, Filial de envio 
@param			_cTipo  , String, Tipo do registro
@return			Nil 	
*****************************************************************************************************/
Method mTreatment(_cCodCli, _cLoja,_cStatus, _cDescri, _cDoc, _cSerie, _cFilEnv, _cTipo) Class ZAPLV 

Local _aAreaZZX   := GetArea()
Default _cCodCli  := ""
Default _cLoja    := ""
Default _cStatus  := ""
Default _cDescri  := ""
Default _cDoc     := ""
Default _cSerie   := ""
Default _cFilEnv  := ""
Default _cTipo    := ""

    RecLock("ZZX", .T.)
        ZZX_CODCLI  := _cCodCli
        ZZX_LOJA    := _cLoja  
        ZZX_STATUS  := _cStatus
        ZZX_DESCRI  := _cDescri
        ZZX_DATA    := Date()  
        ZZX_DOC     := _cDoc
        ZZX_SERIE   := _cSerie  
        ZZX_FILIAL  := _cFilEnv
        ZZX_TIPO    := _cTipo 
    MsUnlock()

    RestArea(_aAreaZZX) 

Return

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Reclock quando houver erro na validacao 
@type   		Method	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			lVlid, Logico, True ocorreu erro na validacao 
@return			Nil 	
*****************************************************************************************************/
Method mCloseArea() Class ZAPLV

    (Self:_cAlias)->(DbCloseArea()) // Fechando a query
    SA1->(DbCloseArea())            // Tabela Cliente 
    SF2->(DbCloseArea())            // Tabela Nota fical eletronica 
    SE1->(DbCloseArea())            // Tabela Contas a receber
    VO1->(DbCloseArea())            // Tabela Ordem de servico
    ZZX->(DbCloseArea())            // Tabela log whatsapp

Return 

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Reclock quando houver erro na validacao 
@type   		Method	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			lVlid, Logico, True ocorreu erro na validacao 
@return			Nil 	
*****************************************************************************************************/
Method mLockValid(lVlid) Class ZAPLV

Default lVlid := .F. 

    If lVlid 
        RecLock("SF2", .F.)
            SF2->F2_X_ZAPOB := AllTrim("Erro na validacao ")
        SF2->(MsUnlock())      
    EndIf 

Return 

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo para zerar as variaveis, quantidade do boleto e os 
@type   		Method	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			
@return			Nil 	
*****************************************************************************************************/
Method mZerarVar() Class ZAPLV

    Self:_nCntBol := 0
    Self:_nCntOS  := 0
    Self:_nCntOrc := 0

Return 

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo para preparar variaveis do boleto 
@type   		Method 
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			cDocumento  , String, Numero da nota
@param			cSerie      , String, Serie da nota
@param			cArqXML     , String, Nome do arquivo XML 
@param			lMostra     , Logico, Se habilitado mostrar o XML da nota
@return			Logico			
*****************************************************************************************************/
Method mPrpBol(_cNumBol, _cPrefx, _cClient, _cLoja, _cFil, _cSerBol, _cEmisBol) Class ZAPLV 

    _cNumBol    := (Self:_cAlias)->F2_DOC 
    _cPrefx     := (Self:_cAlias)->F2_PREFIXO 
    _cClient    := (Self:_cAlias)->F2_CLIENTE 
    _cLoja      := (Self:_cAlias)->F2_LOJA 
    _cFil       := (Self:_cAlias)->F2_FILIAL 
    _cSerBol    := (Self:_cAlias)->F2_SERIE
    _cEmisBol   := (Self:_cAlias)->F2_EMISSAO

Return

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo para gerar query do orcamento
@type   		Method 
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			_cOs  , String, Numero da OS
@return			Logico			
*****************************************************************************************************/
Method mTrackOs(_cOs) Class ZAPLV

Local _cAlOs  := GetNextAlias() 
Local _cQryOs := ""
Local _LVldOs := .F. 

    _cQryOs := " SELECT                                                             " + CRLF
    _cQryOs += " 	    VO1_NUMOSV,                                                 " + CRLF
    _cQryOs += " 	    VO3_TIPTEM,                                                 " + CRLF
    _cQryOs += " 	    VO4_TIPTEM                                                  " + CRLF
    _cQryOs += " FROM                                                               " + CRLF
    _cQryOs += " 	" + RetSQLName("VO1") + " VO1                                   " + CRLF
    _cQryOs += " LEFT JOIN "+ RetSqlName("VO3") +" VO3 ON" + RetSqlDel("VO3")         + CRLF
    _cQryOs += "       AND VO3_NUMOSV = VO1_NUMOSV                                  " + CRLF 
    _cQryOs += "       AND VO3_FILIAL = VO1_FILIAL                                  " + CRLF   
    _cQryOs += " LEFT JOIN "+ RetSqlName("VO4") +" VO4 ON" + RetSqlDel("VO4")         + CRLF
    _cQryOs += "       AND VO4_NUMOSV = VO1_NUMOSV                                  " + CRLF 
    _cQryOs += "       AND VO4_FILIAL = VO1_FILIAL                                  " + CRLF
    _cQryOs += " LEFT JOIN "+ RetSqlName("VOO") +" VOO ON" + RetSqlDel("VOO")         + CRLF
    _cQryOs += "       AND VOO_NUMOSV = VO1_NUMOSV                                  " + CRLF 
    _cQryOs += "       AND VOO_FILIAL = VO1_FILIAL                                  " + CRLF      
    _cQryOs += " WHERE                                                              " + CRLF
    _cQryOs += " 	    VOO_NUMNFI = '"+(Self:_cAlias)->F2_DOC +"'                  " + CRLF
    _cQryOs += " 	    AND VOO_FILIAL = '"+(Self:_cAlias)->F2_FILIAL+"'            " + CRLF 
    _cQryOs += " 	    AND VOO_SERNFI = '"+(Self:_cAlias)->F2_SERIE+"'             " + CRLF 
    _cQryOs += " 	    AND VO1.D_E_L_E_T_ = ''                                     " + CRLF 

    DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQryOs), _cAlOs, .T. , .F.)

    DbSelectArea("VO1")
    VO1->(DbSetOrder(1))
    If !Empty((_cAlOs)->VO1_NUMOSV)
        VO1->(DbSeek(xFilial("VO1") + (_cAlOs)->VO1_NUMOSV))
        _cOs        := VO1->VO1_NUMOSV
        _LVldOs     := ::mVldOs(_cAlOs)

        Conout("Numero os:" + VO1->VO1_NUMOSV + "Filial: " + VO1->VO1_FILIAL )

    EndIf 

Return(_LVldOs)

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo para gerar query do orcamento
@type   		Method 
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			_cOs  , String, Numero da OS
@return			Logico			
*****************************************************************************************************/
Method mVldOs(_cAlOs, _cOs) Class ZAPLV


    DbSelectArea(_cAlOs)
    (_cAlOs)->(DbGoTop())
    While (_cAlOs)->(!Eof())

        If Empty((_cAlOs)->VO1_NUMOSV)
            Return(.F.)
        EndIf 

        If !Empty((_cAlOs)->VO3_TIPTEM)
            If (AllTrim((_cAlOs)->VO3_TIPTEM) <> "CP" .AND. AllTrim((_cAlOs)->VO3_TIPTEM) <> "CS")
                Return(.F.)
            EndIF 
        EndIF

        If !Empty((_cAlOs)->VO4_TIPTEM)
            If  (AllTrim((_cAlOs)->VO4_TIPTEM) <> "CS" .AND.  AllTrim((_cAlOs)->VO4_TIPTEM) <> "CP")
                Return(.F.)
            EndIf 
        EndIf 

        (_cAlOs)->(DbSkip())

    EndDo 

    (_cAlOs)->(DbCloseArea())

Return(.T.)

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo para preparar os parametros para a impressao do relatorio RPS
@type   		Method 
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			
@return			Logico			
*****************************************************************************************************/
Method mRelRPS(_cArqRps, _cPastRPS) Class ZAPLV 

    _cPar01 := Stod((Self:_cAlias)->F2_EMISSAO)     // Data inicial
    _cPar02 := Stod((Self:_cAlias)->F2_EMISSAO)     // Data final 
    _cPar03 := "      "                             // Cliente inicial
    _cPar04 := "ZZZZZZ"                             // Cliente final
    _cPar05 := (Self:_cAlias)->F2_DOC               // Nota inicial     
    _cPar06 := (Self:_cAlias)->F2_DOC               // Nota final 
    _cPar07 := 1                                    // Numeros de copias
    _cPar08 := 2                                    // Imprime cancelados 1 - sim 2 - nao
    _cPar09 := (Self:_cAlias)->F2_FILIAL            // Filial - customizado lucas rocha vieira 

    //--------------------------------------------------------------------------------------
    // Funcao para criar o relatorio RPS 
    //--------------------------------------------------------------------------------------
    U_xMATR968(_cPar01, _cPar02, _cPar03, _cPar04, _cPar05, _cPar06,_cPar07,;
                _cPar08, _cPar09, _cArqRps, _cPastRPS )

Return

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Função que gera o arquivo xml da nota (normal ou cancelada) através do 
                documento e da série disponibilizados
@type   		Method 
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			cDocumento  , String, Numero da nota
@param			cSerie      , String, Serie da nota
@param			cArqXML     , String, Nome do arquivo XML 
@param			lMostra     , Logico, Se habilitado mostrar o XML da nota
@return			Logico			
*****************************************************************************************************/
Method mXML(cDocumento, cSerie, cArqXML, lMostra) Class ZAPLV 

    Local aArea        := GetArea()
    Local cURLTss      := PadR(GetNewPar("MV_SPEDURL","http://"),250)  
    Local oWebServ
    Local cIdEnt       := StaticCall(SPEDNFE, GetIdEnt)
    Local _lRetorno    := .F.
    Local cTextoXML    := ""
    Default cDocumento := ""
    Default cSerie     := ""
    Default cArqXML    := GetTempPath()+"arquivo_"+cSerie+cDocumento+".xml"
    Default lMostra    := .F.
     
    //Se tiver documento
    If !Empty(cDocumento)
        cDocumento := PadR(cDocumento, TamSX3('F2_DOC')[1])
        cSerie     := PadR(cSerie,     TamSX3('F2_SERIE')[1])
         
        //Instancia a conexão com o WebService do TSS    
        oWebServ:= WSNFeSBRA():New()
        oWebServ:cUSERTOKEN        := "TOTVS"
        oWebServ:cID_ENT           := cIdEnt
        oWebServ:oWSNFEID          := NFESBRA_NFES2():New()
        oWebServ:oWSNFEID:oWSNotas := NFESBRA_ARRAYOFNFESID2():New()
        aAdd(oWebServ:oWSNFEID:oWSNotas:oWSNFESID2,NFESBRA_NFESID2():New())
        aTail(oWebServ:oWSNFEID:oWSNotas:oWSNFESID2):cID := (cSerie+cDocumento)
        oWebServ:nDIASPARAEXCLUSAO := 0
        oWebServ:_URL              := AllTrim(cURLTss)+"/NFeSBRA.apw"   
         
        //Se tiver notas
        If oWebServ:RetornaNotas()
         
            //Se tiver dados
            If Len(oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3) > 0
             
                //Se tiver sido cancelada
                If oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFECANCELADA != Nil
                    cTextoXML := oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFECANCELADA:cXML
                     
                //Senão, pega o xml normal
                Else
                    cTextoXML := oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFE:cXML
                EndIf
                 
                //Gera o arquivo
                MemoWrite(cArqXML, cTextoXML)
                _lRetorno := .T.
                 
                //Se for para mostrar, será mostrado um aviso com o conteúdo
                If lMostra
                    Aviso("mXML", cTextoXML, {"Ok"}, 3)
                EndIf
                 
            //Caso não encontre as notas, mostra mensagem
            Else
                ConOut("mXML > Verificar parâmetros, documento e série não encontrados ("+cDocumento+"/"+cSerie+")...")
                 
                If lMostra
                    Aviso("mXML", "Verificar parâmetros, documento e série não encontrados ("+cDocumento+"/"+cSerie+")...", {"Ok"}, 3)
                EndIf
            EndIf
         
        //Senão, houve erros na classe
        Else
            ConOut("mXML > "+IIf(Empty(GetWscError(3)), GetWscError(1), GetWscError(3))+"...")
             
            If lMostra
                Aviso("mXML", IIf(Empty(GetWscError(3)), GetWscError(1), GetWscError(3)), {"Ok"}, 3)
            EndIf
        EndIf
    EndIf

    RestArea(aArea)

Return(_lRetorno)


/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo que gera a danfe e o xml de uma nota em uma pasta passada por parâmetro
@type   		Method 
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			cNota       , String, Numero da nota 
@param			cSerie      , String, Serie da nota 
@param			cPasta      , String, Nome da pasta
@param			cArqDanfe   , String, Nome do arquivo  
@return			Nil 		
*****************************************************************************************************/
Method mDanfe(cNota, cSerie, cPasta, cArqDanfe) Class ZAPLV 

    Local aArea         := GetArea()
    Local _aAreaSX1     := SX1->(GetArea())
    Local cIdent        := ""
    Local cArquivo      := ""
    Local oDanfe        := Nil
    Local lEnd          := .F.
    Private PixelX
    Private PixelY
    Private nConsNeg
    Private nConsTex
    Private oRetNF
    Private nColAux
    Private aNotasBol
    Private NMAXITEM 
    Default cPasta      := GetTempPath()
     

    //Pega o IDENT da empresa
    cIdent := RetIdEnti()
    // 151 001 
    //Se o último caracter da pasta não for barra, será barra para integridade
    If SubStr(cPasta, Len(cPasta), 1) != "\"
        cPasta += "\"
    EndIf
         
    cArquivo  := cArqDanfe

    //Define as perguntas da DANFE 
    Pergunte("NFSIGW", .F.)
    MV_PAR01 :=Self:_cNota                 //Nota Inicial
    MV_PAR02 :=Self:_cNota                 //Nota Final
    MV_PAR03 := cSerie                     //Série da Nota
    MV_PAR04 := 2                          //NF de Saida
    MV_PAR05 := 1                          //Frente e Verso = Sim
    MV_PAR06 := 2                          //DANFE simplificado = Nao
    MV_PAR07 := "19900101"                 //Data de?
    MV_PAR08 := "20491231"                 //Data ate?

    //-----------------------------------------------------------------------------
    // SX1 - Grupo de pergunta 
    // Posiciona nos parametros especifico da nota
    //-----------------------------------------------------------------------------
    DbSelectArea("SX1")
    SX1->(DbSetOrder(1))
            
    If DbSeek("NFSIGW    "+"01")//Altera valor do MV_PAR01
        If RecLock("SX1",.F.)
            X1_CNT01 :=Self:_cNota
            MsUnLock()
        EndIf
    EndIf
            
    If DbSeek("NFSIGW    "+"02")//Altera valor do MV_PAR02
        If RecLock("SX1",.F.)
            X1_CNT01 :=Self:_cNota
            MsUnLock()
        EndIf
    EndIf
            
    If DbSeek("NFSIGW    "+"03")//Altera valor do MV_PAR03
        If RecLock("SX1",.F.)
            X1_CNT01 := cSerie
            MsUnLock()
        EndIf 
    EndIf
            
    If DbSeek("NFSIGW    "+"04")//Altera valor do MV_PAR04
        If RecLock("SX1",.F.)
            X1_PRESEL := IIF(AllTrim(cSerie) == "1", 2, 1) // SERIE 1 SAIDA DIFERENTE DE 1 SERVICOS
            MsUnLock()
        EndIf
    EndIf 

    SX1->(DbCloseArea())

    //----------------------------------------------------------
    // funcao de impressao do danfe formato pdf 
    //----------------------------------------------------------
    oDanfe := FWMSPrinter():New(cArquivo, 6, .F.,cPasta , .T.)

    //Propriedades da DANFE
    oDanfe:SetResolution(78)
    oDanfe:SetLandscape()
    oDanfe:SetPaperSize(DMPAPER_A4)
    oDanfe:SetMargin(60,60,60,60)

    //Força a impressão em PDF
    oDanfe:nDevice  := 6
    oDanfe:cPathPDF := cPasta            
    oDanfe:lServer  := .T.
    oDanfe:lViewPDF := .F.
             
    //Variáveis obrigatórias da DANFE (pode colocar outras abaixo)
	PixelX    := oDanfe:nLogPixelX()
	PixelY    := oDanfe:nLogPixelY()
	nConsNeg  := 0.4
	nConsTex  := 0.5
	oRetNF    := Nil
	lPtImpBol := .F.
	aNotasBol := {}
	nColAux   := 0
    NMAXITEM  := 0

    //Chamando a impressão da danfe no RDMAKE
    StaticCall(DANFEIII, DanfeProc, @oDanfe, @lEnd, cIdent, , , .F.)

    //Imprimi o arquivo 
    oDanfe:Print()

    //Destroi o objeto
    FreeObj(oDanfe)

    RestArea(_aAreaSX1)
    RestArea(aArea)

Return

/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo que definira o tipo de boleto que sera chamado para envio
@type   		Method 
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			cPasta  , String, Nome da pasta Boleto 
@param			_cArqBol, String, Nome do arquivo Boleto 
@return			Nil		
*****************************************************************************************************/
Method mChoiceBol(cPasta, _cArqBol) Class ZAPLV 

Local _aArea        := GetArea()
Local _cFilBolBB    := GETMV("ES_FILBRAS") //Filiais do Norte    - 010111|010112|010113|010114|010115|010116|010117|010118|010120
Local _cFilBolIT    := GETMV("ES_FILITAU") //Filiais centro este - 010103|010104|010105|010106|010107|010109|010110|010119

    If cFilAnt $ _cFilBolBB
    	::mBolBB(cPasta, _cArqBol)
    ElseIf cFilAnt $ _cFilBolIT
        ::mBolItau(cPasta, _cArqBol)
    Endif

    RestArea(_aArea) 

Return


/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo que gera parametros de perguntas e chama a funcao de geracao do boleto
                do banco do mBolItau -
@type   		Method 
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			cPasta  , String, Nome da pasta Boleto 
@param			_cArqBol, String, Nome do arquivo Boleto 
@return			Nil 		
*****************************************************************************************************/
Method mBolItau(cPasta, _cArqBol) Class ZAPLV 

Local _cBcBB    := "341"
Local _cAgc     := "2938" 
Local _cCtc     := "26003"
Local _cSubcta  := "001"

    Self:_nCntBol++

    ::mSpaceField(@_cAgc, @_cCtc)

    //-----------------------------------------------------
    //Carregando variaveis para o envio do boleto 
    //-----------------------------------------------------
    _cVar01 := (Self:_cAliasBol)->E1_PREFIXO        // DO PREFIXO
    _cVar02 := (Self:_cAliasBol)->E1_PREFIXO        // ATE O PREFIXO
    _cVar03 := (Self:_cAliasBol)->E1_NUM            // DO NUMERO 
    _cVar04 := (Self:_cAliasBol)->E1_NUM            // ATE O NUMERO 
    _cVar05 := (Self:_cAliasBol)->E1_PARCELA        // DA PARCELA
    _cVar06 := (Self:_cAliasBol)->E1_PARCELA        // ATE A PARCELA 
    _cVar07 := (Self:_cAliasBol)->E1_NUMBOR         // DO BORDERO
    _cVar08 := (Self:_cAliasBol)->E1_NUMBOR         // ATE O BORDERO
    _cVar09 := (Self:_cAliasBol)->E1_CLIENTE        // DE CLIENTE 
    _cVar10 := (Self:_cAliasBol)->E1_CLIENTE        // ATE O CLIENTE
    _cVar11 := (Self:_cAliasBol)->E1_LOJA           // DE LOJA 
    _cVar12 := (Self:_cAliasBol)->E1_LOJA           // ATE LOJA 
    _dVar13 := Stod((Self:_cAliasBol)->E1_EMISSAO)  // DE EMISSAO 
    _dVar14 := Stod((Self:_cAliasBol)->E1_EMISSAO)  // ATE EMISSAO 
    _dVar15 := Stod((Self:_cAliasBol)->E1_VENCTO)   // DE VENCIMENTO 
    _dVar16 := Stod((Self:_cAliasBol)->E1_VENCTO)   // ATE VENCIMENTO 
    _cVar17 := _cBcBB                               // BANCO                    _cVar17 := "341"        
    _cVar18 := _cAgc                                // AGENCIA                  _cVar18 := "2938 "     
    _cVar19 := _cCtc                                // CONTA                    _cVar19 := "26003    " 
    _cVar20 := _cSubcta                             // SUB CONTA                _cVar20 := "001"               
    _cVar21 := ""                                   // PARAMETRO DO FONTE BOLBBR     
    _cVar22 := (Self:_cAliasBol)->E1_TIPO           // TIPO                

    //----------------------------------------------------------------------
    // Funcao para gerar o boleto do banco do brasil - BOLBBR
    // A variavel _nCntBol tem a funcao de fazer as contagens do boleto, 
    // assim evitando duplicidade no arquivo
    //----------------------------------------------------------------------
    u_mcmitau(_cVar01, _cVar02,_cVar03, _cVar04, _cVar05, _cVar06,_cVar07,_cVar08,_cVar09,_cVar10,_cVar11,_cVar12,;
              _dVar13,_dVar14,_dVar15,_dVar16,_cVar17,_cVar18,_cVar19,_cVar20,_cVar21, cPasta, _cArqBol, _cVar22, Self:_cAliasBol) 


Return


/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo que gera parametros de perguntas e chama a funcao de geracao do boleto
                do banco do Banco do Brasil - U_BOLBBR()
@type   		Method 
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			cPasta  , String, Nome da pasta Boleto 
@param			_cArqBol, String, Nome do arquivo Boleto 
@return			Nil 	
*****************************************************************************************************/
Method mBolBB(cPasta, _cArqBol) Class ZAPLV 

Local _cBcBB    := "001"
Local _cAgc     := "3382" 
Local _cCtc     := "201013"
Local _cSubcta  := "001"



    Self:_nCntBol++

    ::mSpaceField(@_cAgc, @_cCtc)

    //-----------------------------------------------------
    //Carregando variaveis para o envio do boleto 
    //-----------------------------------------------------
    _cVar01 := (Self:_cAliasBol)->E1_PREFIXO        // DO PREFIXO
    _cVar02 := (Self:_cAliasBol)->E1_PREFIXO        // ATE O PREFIXO
    _cVar03 := (Self:_cAliasBol)->E1_NUM            // DO NUMERO 
    _cVar04 := (Self:_cAliasBol)->E1_NUM            // ATE O NUMERO 
    _cVar05 := (Self:_cAliasBol)->E1_PARCELA        // DA PARCELA
    _cVar06 := (Self:_cAliasBol)->E1_PARCELA        // ATE A PARCELA 
    _cVar07 := (Self:_cAliasBol)->E1_NUMBOR         // DO BORDERO
    _cVar08 := (Self:_cAliasBol)->E1_NUMBOR         // ATE O BORDERO
    _cVar09 := (Self:_cAliasBol)->E1_CLIENTE        // DE CLIENTE 
    _cVar10 := (Self:_cAliasBol)->E1_CLIENTE        // ATE O CLIENTE
    _cVar11 := (Self:_cAliasBol)->E1_LOJA           // DE LOJA 
    _cVar12 := (Self:_cAliasBol)->E1_LOJA           // ATE LOJA 
    _dVar13 := Stod((Self:_cAliasBol)->E1_EMISSAO)  // DE EMISSAO 
    _dVar14 := Stod((Self:_cAliasBol)->E1_EMISSAO)  // ATE EMISSAO 
    _dVar15 := Stod((Self:_cAliasBol)->E1_VENCTO)   // DE VENCIMENTO 
    _dVar16 := Stod((Self:_cAliasBol)->E1_VENCTO)   // ATE VENCIMENTO 
    _cVar17 := _cBcBB                               // BANCO        (Self:_cAliasBol)->A6_COD        
    _cVar18 := _cAgc                                // AGENCIA      (Self:_cAliasBol)->A6_AGENCIA     
    _cVar19 := _cCtc                                // CONTA        (Self:_cAliasBol)->A6_NUMCON   
    _cVar20 := _cSubcta                             // SUB CONTA               
    _cVar21 := ""                                   // PARAMETRO DO FONTE BOLBBR      
    _cVar22 := (Self:_cAliasBol)->E1_TIPO           // TIPO         

    //----------------------------------------------------------------------
    // Funcao para gerar o boleto do banco do brasil - BOLBBR
    // A variavel _nCntBol tem a funcao de fazer as contagens do boleto, 
    // assim evitando duplicidade no arquivo
    //----------------------------------------------------------------------
        
    u_BOLBBR(_cVar01, _cVar02,_cVar03, _cVar04, _cVar05, _cVar06,_cVar07,_cVar08,_cVar09,_cVar10,_cVar11,_cVar12,;
              _dVar13,_dVar14,_dVar15,_dVar16,_cVar17,_cVar18,_cVar19,_cVar20,_cVar21, cPasta, _cArqBol, _cVar22, Self:_cAliasBol) 

Return


/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo que gera parametros de perguntas e chama a funcao de geracao do boleto
                do banco do Banco do Brasil - U_BOLBBR() e do banco do Itau - u_mcmitau
@type   		Method 
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			
@return					
*****************************************************************************************************/
Method mBolQr(_cNumBol, _cPrefx, _cClient, _cLoja, _cFil, _cSerBol, _cEmisBol) Class ZAPLV 

Local _cQry         := ""
Local _dDtBol       := GetNewPar("MV_DATABOL", Date())

Self:_cAliasBol     := GetNextAlias()

Default _cNumBol    := ""
Default _cPrefx     := ""
Default _cClient    := ""
Default _cLoja      := ""
Default _cFil       := ""
Default _cTbol      := ""

    _cQry := " SELECT                                                       " + CRLF
    _cQry += " 	    E1_PREFIXO,                                             " + CRLF
    _cQry += " 	    E1_NUM,                                                 " + CRLF
    _cQry += " 	    E1_PARCELA,                                             " + CRLF
    _cQry += " 	    E1_CLIENTE,                                             " + CRLF
    _cQry += " 	    E1_NUMBOR,                                              " + CRLF
    _cQry += " 	    E1_LOJA,                                                " + CRLF
    _cQry += " 	    E1_EMISSAO,                                             " + CRLF
    _cQry += " 	    E1_VENCTO,                                              " + CRLF
    _cQry += " 	    E1_FILIAL,                                              " + CRLF
    _cQry += " 	    E1_PORTADO,                                             " + CRLF
    _cQry += " 	    E1_AGEDEP,                                              " + CRLF
    _cQry += " 	    E1_CONTA,                                               " + CRLF
    _cQry += " 	    E1_VALOR,                                               " + CRLF
    _cQry += " 	    E1_TIPO                                                 " + CRLF
    _cQry += " FROM                                                         " + CRLF
    _cQry += " 	" + RetSQLName("SE1") + " E1                                " + CRLF  
    _cQry += " 	WHERE                                                       " + CRLF
    _cQry += "      E1_NUM          = '"+_cNumBol+"'                        " + CRLF
    _cQry += "      AND E1_PREFIXO  = '"+_cPrefx+"'                         " + CRLF 
    _cQry += "      AND E1_SERIE    = '"+_cSerBol+"'                        " + CRLF 
    _cQry += "      AND E1_CLIENTE  ='"+_cClient+"'                         " + CRLF 
    _cQry += "      AND E1_LOJA     = '"+_cLoja+"'                          " + CRLF 
    _cQry += " 	    AND E1_EMISSAO >= '"+Dtos(_dDtBol)+"'                   " + CRLF 
    _cQry += " 	    AND E1_EMISSAO  = '"+_cEmisBol+"'                       " + CRLF 
    //_cQry += " 	    AND E1_FILORIG  = '"+_cFil+"'                           " + CRLF
    _cQry += " 	    AND E1_STATUS = 'A'                                     " + CRLF 
    //_cQry += " 	    AND E1_ZBOLENV  = ''                                    " + CRLF
    //_cQry += " 	    AND E1_ZBOLHRS  = ''                                    " + CRLF
    //_cQry += " 	    AND E1_ZBOLRES  = ''                                    " + CRLF
    //_cQry += " 	  AND E1_ZBOLENV = ''                                     " + CRLF // Nao foi enviada a menasgem
    _cQry += " 	    AND E1.D_E_L_E_T_ = ''                                  " + CRLF 

    DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQry), Self:_cAliasBol , .T. , .F.)

    If !Empty((Self:_cAliasBol)->E1_NUM)
        Return(.T.)
    EndIf 

Return(.F.)  


/**************************************************************************************************
{Protheus.doc} ZAPLV
@description	Metodo para tratar os tamanho dos campos 
@type   		Method 
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			_cAgc, String, Numero da Agencia
@param			_cCtc, String, Numero da Conta
@return		    Nil 			
*****************************************************************************************************/
Method mSpaceField(_cAgc, _cCtc) Class ZAPLV 

Local nTamAg  := Len(Space(TamSX3("A6_AGENCIA")[01]))
Local nTamCt  := Len(Space(TamSX3("A6_NUMCON")[01]))
Local _nSpace := 0

    If  Len(_cAgc) != nTamAg
        _nSpace := nTamAg - Len(_cAgc)
        _cAgc   := _cAgc + Space(_nSpace)
    EndIf 

    If  Len(_cCtc) != nTamCt
        _nSpace := nTamCt - Len(_cCtc)
        _cCtc   := _cCtc + Space(_nSpace)
    EndIf 

Return 
