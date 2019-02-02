module Front.Utils exposing (..)

import Result
import Debug exposing (log)
import Html exposing (Html, input, tr, th, text, button)
import Html.Events exposing (onInput, onClick)
import Http exposing (request, expectString, stringBody)


localPath : String
localPath =
  "/save/local"


dbPath : String
dbPath =
  "/save/db"


handleSession : (String -> a) -> Result b String -> a
handleSession hanlder result =
  case result of 
    Ok str ->
      hanlder str

    Err msg ->
      log "msg" msg
        |> \_ -> hanlder "No session"


makeRow : (String -> msg) -> msg -> String -> Html msg
makeRow handleInput saveInput value =
  tr []
    [ th [] [ input [ onInput handleInput ] [] ]
    , th [] [ button [ onClick saveInput ] [ text "Save" ] ]
    , th [] [ text value ]
    ]


postSession : (Http.Request String -> a) -> String -> String -> a
postSession handler str url  =
    { method = "POST"
    , headers = []
    , url = url
    , body = stringBody "text/plain" str
    , expect = expectString
    , timeout = Nothing
    , withCredentials = False
    }
      |> request
      |> handler


spreadTuple: (a -> b -> c) -> (a, b) -> c
spreadTuple fun (handler, task) =
  fun handler task
    
