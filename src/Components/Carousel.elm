module Components.Carousel exposing (update, Model, Msg, init, view, subscriptions)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import FeatherIcons as Icons
import Task
import Time exposing (..)
import Server

--Model

type alias Model =
  {
    source: String
    , current: Int
    , total: Int
    , dir: Direction
  }

type Direction
  = Right
  | Left

init : Model
init =
  {
    source = "src/img/1.png"
    , current = 1
    , total = 4
    , dir = Right
  }

--Update

type Msg
    = SwitchRight Int
    | SwitchLeft Int

update : Msg -> Model -> Model
update msg model =
  case msg of
    SwitchRight i ->
      ({ model | current = handle (i+1) model
         , source = "src/img/" ++ String.fromInt (handle (i+1) model) ++ ".png"
         , dir = Right
      })

    SwitchLeft i -> 
      ({ model | current = handle (i-1) model
         , source = "src/img/" ++ String.fromInt (handle (i-1) model) ++ ".png"
         , dir = Left
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
  let
    url = "url(" ++ model.source ++ ")"
  in
    div [class "container-fluid text-center"
        , style "height" "1000px"
        , style "background-image" url
        , style "background-color" "gray"
        , style "background-size" "cover"
        , style "transition" "all .5s ease-in-out"
 ]
    [
      div[ style "margin-top" "500px" ][
        button [ style "background" "Transparent"
        , style "border" "none"
        , style "color" "white"
        , style "position" "absolute"
        , style "left" "0px"
        , style "opacity" "0.7"
        , style "outline" "none"
        , onClick (SwitchLeft model.current) ]
        [ 
          Icons.chevronLeft |> Icons.withSize 80 |> Icons.withStrokeWidth 3 |> Icons.toHtml [] 
        ]
        , button  [ style "background" "Transparent"
        , style "border" "none"
        , style "color" "white"
        , style "position" "absolute"
        , style "right" "0px"
        , style "opacity" "0.7"
        , style "outline" "none"
        , onClick (SwitchRight model.current) ]
        [ 
          Icons.chevronRight |> Icons.withSize 80 |> Icons.withStrokeWidth 3 |> Icons.toHtml [] 
        ]
      ]
    ]


subscriptions : Model -> Sub Msg
subscriptions model =
  Time.every 5000 (\_ ->
    (
    case model.dir of
      Right -> 
        SwitchRight model.current
      Left ->
        SwitchLeft model.current
    )
  )
