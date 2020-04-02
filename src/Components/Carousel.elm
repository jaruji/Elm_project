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
  }

type Direction
  = Right
  | Left

init : Array String -> Model
init imgs =
  {
    source = imgs
    , current = 0
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
      ({ model | current = handle (i + 1) model
         , dir = Right
      })

    SwitchLeft i -> 
      ({ model | current = handle (i - 1) model
         , dir = Left
      })

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
            --, style "box-shadow" "0px 10px 5px #888, 0px -10px 5px #888"
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

            , h1 [ class "lead"
            , style "color" "white"
            , style "font-size" "60px" 
            , style "opacity" "0.9" ][
              text "Get Creative." 
            ]
            
            , h3 [ class "lead" 
            , style "color" "white" 
            , style "font-size" "30px"
            , style "opacity" "0.9"
            , style "margin-top" "-25px" ][
              text "Website created for sharing images - powered by Elm."
            ]
            , div [ style "margin-top" "350px" ] (Array.toList (Array.map viewBullet model.source ))
          ]
        ]
    Nothing ->
      div[][]


viewBullet: String -> Html msg
viewBullet string = 
  button[ style "outline" "none" 
  , style "border" "none"
  , style "background" "Transparent"
  , style "opacity" "0.7"
  , style "color" "white"
  , style "position" "relative"
  ][
    Icons.circle |> Icons.withSize 20 |> Icons.withStrokeWidth 3 |> Icons.toHtml [] 
  ]

subscriptions: Model -> Sub Msg
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
