module Front.Utils exposing (..)

import Result exposing (withDefault)
import Html exposing (Html, input, tr, th, text, button)
import Html.Events exposing (onInput, onClick)
import Http exposing (request, expectString, stringBody)


{-| Define the application state
-}
type alias Model =
    { local: Entry 
    , db: Entry
    }


{-| Define state for single component of the app
-}
type alias Entry =
    { input: String 
    , value: String
    }


{-| Initial state of the application
-}
model : Model
model =
    { local = 
        { input = ""
        , value = "Wait status"
        }
    , db =
        { input = ""
        , value = "Wait status"
        }
    }


{-| Path to "/save/local" API
-}
localPath : String
localPath =
  "/save/local"


{-| Path to "/save/db" API
-}
dbPath : String
dbPath =
  "/save/db"


{-| Process Result with handler, fallback to "No session" for Error value
-}
handleSession : (String -> a) -> Result b String -> a
handleSession hanlder result =
    result
        |> withDefault "No session"
        |> hanlder


{-| Create row component, which is the key part of UI
-}
makeRow : (String -> msg) -> msg -> String -> Html msg
makeRow handleInput saveInput value =
  tr []
    [ th [] [ input [ onInput handleInput ] [] ]
    , th [] [ button [ onClick saveInput ] [ text "Save" ] ]
    , th [] [ text value ]
    ]


{-| Prepare Request for text and tag it with handler
-}
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


{-| Apply fst and snd values of tuple as function args
-}
spreadTuple: (a -> b -> c) -> (a, b) -> c
spreadTuple fun (handler, task) =
  fun handler task
    
