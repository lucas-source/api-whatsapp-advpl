#INCLUDE 'TOTVS.CH'

/**************************************************************************************************
{Protheus.doc} ZAPFUNCTION
@description	Funcao para instaciar a classe ZAPLV e realizar a chamada dos metodos da classe
@type   		Class	
@author			Lucas Rocha Vieira
@version   		1.00
@since     		22/09/2021
@database		22/09/2021
@country		Brasil
@language		PT-BR
@obs			22/09/2021 - Controle de documentacao
@param			
@return		   Nil				
*****************************************************************************************************/
User Function ZAPFUNCTION()

Local oObjZap := ZAPLV():New()
Local _lOk    := .F.

    //---------------------------------------------------------------------------------
    //Starta o ambiente caso ele nao estiver inicializado
    //---------------------------------------------------------------------------------
    oObjZap:mResetEnvir()
    //---------------------------------------------------------------------------------
    //Realiza a query
    //---------------------------------------------------------------------------------
    oObjZap:mQryzap()  
    //---------------------------------------------------------------------------------
    //Caso estiver notas para gerar e chamado a funcao para validar as informacoes      
    //---------------------------------------------------------------------------------
    If !Empty((oObjZap:_cAlias)->SF2REC)
        _lOk := oObjZap:mLoop()
    EndIf 

Return 
