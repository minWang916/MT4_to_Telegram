#property copyright "Copyright 2022, Orchard Forex"
#property link "https://www.orchardforex.com"
#property version "1.00"
//#property script_show_inputs
//#property script_show_confirm

#property strict

const string TelegramBotToken = "6251252343:AAFh1FXCQptj4Etk9phSRtzFiR4aLK7NwpU";
const string ChatId           = "-1001872392239";
const string TelegramApiUrl   = "https://api.telegram.org"; // Add this to Allow URLs

const int    UrlDefinedError  = 4066; // Because MT4 and MT5 are different

void         OnStart( void ) {

   // Added because bmp files seem to have stopped working, possibly a file format issue
   string fileType = "png";
   string fileName = "MyScreenshot." + fileType;

   // Save a screen shot
   ChartRedraw(); // Make sure the chart is up to date
   ChartScreenShot( 0, fileName, 1024, 768, ALIGN_RIGHT );

   SendTelegramMessage( TelegramApiUrl, TelegramBotToken, ChatId,
                                "Test message " + TimeToString( TimeLocal() ) ); // no image attached
   SendTelegramMessage( TelegramApiUrl, TelegramBotToken, ChatId,
                                "Test message with image " + TimeToString( TimeLocal() ), fileName );
}

bool SendTelegramMessage( string url, string token, string chat, string text,
                          string fileName = "" ) {

   string headers    = "";
   string requestUrl = "";
   char   postData[];
   char   resultData[];
   string resultHeaders;
   int    timeout = 5000; // 1 second, may be too short for a slow connection

   ResetLastError();

   if ( fileName == "" ) {
      requestUrl =
         StringFormat( "%s/bot%s/sendmessage?chat_id=%s&text=%s", url, token, chat, text );
   }
   else {
      requestUrl = StringFormat( "%s/bot%s/sendPhoto", url, token );
      if ( !GetPostData( postData, headers, chat, text, fileName ) ) {
         return ( false );
      }
   }

   ResetLastError();
   int response =
      WebRequest( "POST", requestUrl, headers, timeout, postData, resultData, resultHeaders );

   switch ( response ) {
   case -1: {
      int errorCode = GetLastError();
      Print( "Error in WebRequest. Error code  =", errorCode );
      if ( errorCode == UrlDefinedError ) {
         //--- url may not be listed
         PrintFormat( "Add the address '%s' in the list of allowed URLs", url );
      }
      break;
   }
   case 200:
      //--- Success
      Print( "The message has been successfully sent" );
      break;
   default: {
      string result = CharArrayToString( resultData );
      PrintFormat( "Unexpected Response '%i', '%s'", response, result );
      break;
   }
   }

   return ( response == 200 );
}

bool GetPostData( char &postData[], string &headers, string chat, string text, string fileName ) {

   ResetLastError();

   if ( !FileIsExist( fileName ) ) {
      PrintFormat( "File '%s' does not exist", fileName );
      return ( false );
   }

   int flags = FILE_READ | FILE_BIN;
   int file  = FileOpen( fileName, flags );
   if ( file == INVALID_HANDLE ) {
      int err = GetLastError();
      PrintFormat( "Could not open file '%s', error=%i", fileName, err );
      return ( false );
   }

   int   fileSize = ( int )FileSize( file );
   uchar photo[];
   ArrayResize( photo, fileSize );
   FileReadArray( file, photo, 0, fileSize );
   FileClose( file );

   string hash = "";
   AddPostData( postData, hash, "chat_id", chat );
   if ( StringLen( text ) > 0 ) {
      AddPostData( postData, hash, "caption", text );
   }
   AddPostData( postData, hash, "photo", photo, fileName );
   ArrayCopy( postData, "--" + hash + "--\r\n" );

   headers = "Content-Type: multipart/form-data; boundary=" + hash + "\r\n";

   return ( true );
}

void AddPostData( uchar &data[], string &hash, string key = "", string value = "" ) {

   uchar valueArr[];
   StringToCharArray( value, valueArr, 0, StringLen( value ) );

   AddPostData( data, hash, key, valueArr );
   return;
}

void AddPostData( uchar &data[], string &hash, string key, uchar &value[], string fileName = "" ) {

   if ( hash == "" ) {
      hash = Hash();
   }

   ArrayCopy( data, "\r\n" );
   ArrayCopy( data, "--" + hash + "\r\n" );
   if ( fileName == "" ) {
      ArrayCopy( data, "Content-Disposition: form-data; name=\"" + key + "\"\r\n" );
   }
   else {
      ArrayCopy( data, "Content-Disposition: form-data; name=\"" + key + "\"; filename=\"" +
                          fileName + "\"\r\n" );
   }
   ArrayCopy( data, "\r\n" );
   ArrayCopy( data, value, ArraySize( data ) );
   ArrayCopy( data, "\r\n" );

   return;
}

void ArrayCopy( uchar &dst[], string src ) {

   uchar srcArray[];
   StringToCharArray( src, srcArray, 0, StringLen( src ) );
   ArrayCopy( dst, srcArray, ArraySize( dst ), 0, ArraySize( srcArray ) );
   return;
}

string Hash() {

   uchar  tmp[];
   string seed = IntegerToString( TimeCurrent() );
   int    len  = StringToCharArray( seed, tmp, 0, StringLen( seed ) );
   string hash = "";
   for ( int i = 0; i < len; i++ )
      hash += StringFormat( "%02X", tmp[i] );
   hash = StringSubstr( hash, 0, 16 );

   return ( hash );
}
