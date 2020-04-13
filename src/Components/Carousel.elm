module Components.Carousel exposing (update, Model, Msg, init, view, subscriptions)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import FeatherIcons as Icons
import Task
import Time exposing (..)
import Server
import Array exposing (..)

--Model

type alias Model =
  {
    source: Array String
    , current: Int
    , dir: Direction
    , counter: Count
  }

type Direction
  = Right
  | Left

type Count
  = Stop
  | Start

init : Array String -> Model
init imgs =
  {
    source = imgs
    , current = 0
    , dir = Right
    , counter = Start
  }

--Update

type Msg
    = SwitchRight Int
    | SwitchLeft Int
    | Jump Int
    | Reset

update : Msg -> Model -> Model
update msg model =
  case msg of
    SwitchRight i ->
      ({ model | current = handle (i + 1) model
         , dir = Right, counter = Stop
      })

    SwitchLeft i -> 
      ({ model | current = handle (i - 1) model
         , dir = Left, counter = Stop
      })

    Jump i ->
      ({ model | current = i, counter = Stop}) 

    Reset ->
      ({ model | counter = Start })

handle : Int -> Model -> Int
handle current model =
  if(current < 0) then
    (Array.length model.source - 1)
  else if (current >= Array.length model.source) then
    0
  else
    current

--View
view : Model -> Html Msg
view model =
  case Array.get model.current model.source of
    Just img ->
      let 
        url = "url(" ++ img ++ ")"
      in
        div [class "container-fluid text-center image"
            , style "height" "1000px"
            , style "width" "100%"
            , style "background-image" url
            , style "background-color" "gray"
            , style "background-size" "cover"
            , style "overflow" "hidden"
            , style "transition" "all .5s ease-in-out"
        ][
          div[ style "margin-top" "450px" ][
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
          , div [ style "margin-top" "900px" ] (Array.toList (Array.indexedMap (viewBullet model) model.source ))
        ]
    Nothing ->
      div[][]


viewBullet:  Model -> Int -> String -> Html Msg
viewBullet model index string = 
  button[ style "outline" "none" 
  , style "border" "none"
  , style "background" "Transparent"
  , style "opacity" "0.7"
  , style "color" "white"
  , style "position" "relative"
  , class "preview"
  , onClick (Jump index)
  ][
    if model.current == index then
      Icons.xCircle |> Icons.withSize 20 |> Icons.withStrokeWidth 3 |> Icons.toHtml [] 
    else
      Icons.circle |> Icons.withSize 20 |> Icons.withStrokeWidth 3 |> Icons.toHtml [] 
  ]

subscriptions: Model -> Sub Msg
subscriptions model =
  case model.counter of
    Start ->
      Time.every 5000 (\_ ->
        (
        case model.dir of
          Right -> 
            SwitchRight model.current
          Left ->
            SwitchLeft model.current
        )
      )
    Stop ->
      Time.every 1000 (\_ -> Reset)
