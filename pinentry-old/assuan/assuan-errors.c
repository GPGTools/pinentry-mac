/* Generated automatically by mkerrors */
/* Do not edit! */

#include <stdio.h>
#include "assuan.h"

/**
 * assuan_strerror:
 * @err:  Error code 
 * 
 * This function returns a textual representaion of the given
 * errorcode. If this is an unknown value, a string with the value
 * is returned (Beware: it is hold in a static buffer).
 * 
 * Return value: String with the error description.
 **/
const char *
assuan_strerror (AssuanError err)
{
  const char *s;
  static char buf[25];

  switch (err)
    {
    case ASSUAN_No_Error: s="no error"; break;
    case ASSUAN_General_Error: s="general error"; break;
    case ASSUAN_Out_Of_Core: s="out of core"; break;
    case ASSUAN_Invalid_Value: s="invalid value"; break;
    case ASSUAN_Timeout: s="timeout"; break;
    case ASSUAN_Read_Error: s="read error"; break;
    case ASSUAN_Write_Error: s="write error"; break;
    case ASSUAN_Problem_Starting_Server: s="problem starting server"; break;
    case ASSUAN_Not_A_Server: s="not a server"; break;
    case ASSUAN_Not_A_Client: s="not a client"; break;
    case ASSUAN_Nested_Commands: s="nested commands"; break;
    case ASSUAN_Invalid_Response: s="invalid response"; break;
    case ASSUAN_No_Data_Callback: s="no data callback"; break;
    case ASSUAN_No_Inquire_Callback: s="no inquire callback"; break;
    case ASSUAN_Connect_Failed: s="connect failed"; break;
    case ASSUAN_Accept_Failed: s="accept failed"; break;
    case ASSUAN_Not_Implemented: s="not implemented"; break;
    case ASSUAN_Server_Fault: s="server fault"; break;
    case ASSUAN_Invalid_Command: s="invalid command"; break;
    case ASSUAN_Unknown_Command: s="unknown command"; break;
    case ASSUAN_Syntax_Error: s="syntax error"; break;
    case ASSUAN_Parameter_Error: s="parameter error"; break;
    case ASSUAN_Parameter_Conflict: s="parameter conflict"; break;
    case ASSUAN_Line_Too_Long: s="line too long"; break;
    case ASSUAN_Line_Not_Terminated: s="line not terminated"; break;
    case ASSUAN_No_Input: s="no input"; break;
    case ASSUAN_No_Output: s="no output"; break;
    case ASSUAN_Canceled: s="canceled"; break;
    case ASSUAN_Unsupported_Algorithm: s="unsupported algorithm"; break;
    case ASSUAN_Server_Resource_Problem: s="server resource problem"; break;
    case ASSUAN_Server_IO_Error: s="server io error"; break;
    case ASSUAN_Server_Bug: s="server bug"; break;
    case ASSUAN_No_Data_Available: s="no data available"; break;
    case ASSUAN_Invalid_Data: s="invalid data"; break;
    case ASSUAN_Unexpected_Command: s="unexpected command"; break;
    case ASSUAN_Too_Much_Data: s="too much data"; break;
    case ASSUAN_Inquire_Unknown: s="inquire unknown"; break;
    case ASSUAN_Inquire_Error: s="inquire error"; break;
    case ASSUAN_Invalid_Option: s="invalid option"; break;
    case ASSUAN_Invalid_Index: s="invalid index"; break;
    case ASSUAN_Unexpected_Status: s="unexpected status"; break;
    case ASSUAN_Unexpected_Data: s="unexpected data"; break;
    case ASSUAN_Invalid_Status: s="invalid status"; break;
    case ASSUAN_Locale_Problem: s="locale problem"; break;
    case ASSUAN_Not_Confirmed: s="not confirmed"; break;
    case ASSUAN_Bad_Certificate: s="bad certificate"; break;
    case ASSUAN_Bad_Certificate_Path: s="bad certificate path"; break;
    case ASSUAN_Missing_Certificate: s="missing certificate"; break;
    case ASSUAN_Bad_Signature: s="bad signature"; break;
    case ASSUAN_No_Agent: s="no agent"; break;
    case ASSUAN_Agent_Error: s="agent error"; break;
    case ASSUAN_No_Public_Key: s="no public key"; break;
    case ASSUAN_No_Secret_Key: s="no secret key"; break;
    case ASSUAN_Invalid_Name: s="invalid name"; break;
    case ASSUAN_Cert_Revoked: s="cert revoked"; break;
    case ASSUAN_No_CRL_For_Cert: s="no crl for cert"; break;
    case ASSUAN_CRL_Too_Old: s="crl too old"; break;
    case ASSUAN_Not_Trusted: s="not trusted"; break;
    case ASSUAN_Card_Error: s="card error"; break;
    case ASSUAN_Invalid_Card: s="invalid card"; break;
    case ASSUAN_No_PKCS15_App: s="no pkcs15 app"; break;
    case ASSUAN_Card_Not_Present: s="card not present"; break;
    case ASSUAN_Invalid_Id: s="invalid id"; break;
    default:  sprintf (buf, "ec=%d", err ); s=buf; break;
    }

  return s;
}

