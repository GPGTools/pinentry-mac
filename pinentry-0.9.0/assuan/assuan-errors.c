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
    case ASSUAN_Unknown_Command: s="unknown command"; break;
    case ASSUAN_Syntax_Error: s="syntax error"; break;
    case ASSUAN_Parameter_Conflict: s="parameter conflict"; break;
    case ASSUAN_Line_Too_Long: s="line too long"; break;
    case ASSUAN_Line_Not_Terminated: s="line not terminated"; break;
    case ASSUAN_Canceled: s="canceled"; break;
    case ASSUAN_Invalid_Option: s="invalid option"; break;
    case ASSUAN_Locale_Problem: s="locale problem"; break;
    case ASSUAN_Not_Confirmed: s="not confirmed"; break;
    default:  sprintf (buf, "ec=%d", err ); s=buf; break;
    }

  return s;
}

