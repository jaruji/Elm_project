module Components.Carousel exposing (..)
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
  }

init : Model
init =
  {
    source = "src/img/1.png"
    , current = 1
    , total = 4
  }

--Update

type Msg
    = Switch Int

update : Msg -> Model -> Model
update msg model =
  case msg of
    Switch i ->
      ({ model | current = handle i model
      , source = "src/img/" ++ String.fromInt (handle i model) ++ ".png"
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
        , style "background-size" "cover" ]
    [
      div[ style "margin-top" "500px" ][
        button [ style "background" "Transparent"
        , style "border" "none"
        , style "color" "white"
        , style "position" "absolute"
        , style "left" "0px"
        , style "opacity" "0.7"
        , style "outline" "none"
        , onClick (Switch (model.current - 1)) ]
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
        , onClick (Switch (model.current + 1)) ]
        [ 
          Icons.chevronRight |> Icons.withSize 80 |> Icons.withStrokeWidth 3 |> Icons.toHtml [] 
        ]
      ]
        {--
        , div[style "text-align" "center"][
          text ("<" ++ String.fromInt model.current ++ "/" ++ String.fromInt(model.total) ++ ">")
        ]
        --}
    ]


subscriptions : Model -> Sub Msg
subscriptions model =
  Time.every 5000 (\_ -> Switch (model.current + 1))
