module Front.App exposing (..)

import Html exposing (Html, h2, table, div, text)
import Http exposing (getString, send, toTask)
import Task exposing (attempt)
import List exposing (map, map2)
import Front.Utils exposing(..)

main : Program Never Model Msg
main =
  let 
    getSession = 
      [ getString localPath
      , getString dbPath
      ] 
        |> map toTask
        |> map2 (,) [HandleLocalResponse, HandleDBResponse]
        |> map (spreadTuple <| attempt << handleSession)
        |> Cmd.batch
  in
    Html.program
      { init = ( model, getSession )
      , view = view
      , update = update
      , subscriptions = \ _ -> Sub.none
      }


-- MODEL

type alias Model =
  { local: Entry 
  , db: Entry
  }


type alias Entry =
  { input: String 
  , value: String
  }


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


-- UPDATE

type Msg
  = HandleLocalInput String
  | HandleLocalResponse String
  | HandleDBInput String
  | HandleDBResponse String
  | Send (String -> Msg) (Http.Request String) 


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    HandleLocalInput input ->
      (
        { model
        | local = 
            { value = model.local.value
            , input = input
            }
        }
        , 
        Cmd.none
      )
    
    HandleLocalResponse value ->
      (
        { model
        | local = 
          { value = value
          , input = model.local.input
          }
        }
        , 
        Cmd.none
      )
    
    HandleDBInput input ->
      (
        { model
        | db = 
            { value = model.db.value
            , input = input
            }
        }
        , 
        Cmd.none
      )
    
    HandleDBResponse value ->
      (
        { model
        | db = 
          { value = value
          , input = model.db.input
          }
        }
        , 
        Cmd.none
      )

    Send handler req  ->
      (model, send (handleSession handler) req )


-- VIEW


view : Model -> Html Msg
view model =
  let 
    save =
      postSession << Send
    saveLocal = 
      save HandleLocalResponse model.local.input localPath
    saveDB =
      save HandleDBResponse model.db.input dbPath
  in
    div [ ]
        [ h2 [] [ text "Board demo application" ]
        , table [ ]
            [ makeRow HandleLocalInput saveLocal model.local.value
            , makeRow HandleDBInput saveDB model.db.value
            ]
        ]



      