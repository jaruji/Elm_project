module Components.Carousel exposing (..)
-- module Components.Carousel exposing(..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import FeatherIcons as Icons
--import Animation exposing (px)
import Task
import Time exposing (..)

--TODO: po vyprsani casu sa bude carousel sam pohybovat = DONE

--Model

type alias Model =
  {
    source: String
    , current: Int
    , total: Int
  }

init : Model
init =
  {
    source = "src/img/1.jpg"
    , current = 1
    , total = 5
  }

--Update

type Msg
    = Switch Int

update : Msg -> Model -> Model
update msg model =
  case msg of
    Switch i ->
      ({ model | current = handle i model
      , source = "src/img/" ++ String.fromInt (handle i model) ++ ".jpg"
      })

handle : Int -> Model -> Int
handle current model =
  if(current < 1) then
    model.total
  else if (current > model.total) then
    1
  else
    current

--View
view : Model -> Html Msg
view model =
    div [ style "position" "absolute"
      , style "top" "50%"
      , style "left" "50%"
      , style "transform" "translate(-50%, -50%)"][
      div[][
      button [onClick (Switch (model.current - 1))][Icons.chevronLeft
                |> Icons.withSize 15
                |> Icons.toHtml []]
      , img[src model.source, width 700, height 400] []
      , button [onClick (Switch (model.current + 1))][Icons.chevronRight
                  |> Icons.withSize 15
                  |> Icons.toHtml []]
      ]
      , div[style "text-align" "center"][
        text ("<" ++ String.fromInt model.current ++ "/" ++ String.fromInt(model.total) ++ ">")
      ]
      , div[style  "text-align" "center"][
        button [] [Icons.circle
                  |> Icons.withSize 15
                  |> Icons.toHtml []]
        , button [] [Icons.circle
                  |> Icons.withSize 15
                  |> Icons.toHtml []]
        , button [] [Icons.circle
                  |> Icons.withSize 15
                  |> Icons.toHtml []]
        , button [] [Icons.circle
                  |> Icons.withSize 15
                  |> Icons.toHtml []]
        , button [] [Icons.circle
                  |> Icons.withSize 15
                  |> Icons.toHtml []]
        ]
    ]


subscriptions : Model -> Sub Msg
subscriptions model =
  Time.every 5000 (\_ -> Switch (model.current + 1))



--Main

--main =
--  Browser.sandbox { init = init, update = update, view = view }
