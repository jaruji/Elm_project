module Pages.Home exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Browser.Navigation as Nav
import Components.Carousel as Carousel
import User
import Server
import Array exposing (..)
import FeatherIcons as Icons


type alias Model =
  {
    key: Nav.Key
    , carousel: Carousel.Model
    , user: Maybe User.Model
  } 

type Msg
  = UpdateCarousel Carousel.Msg

init: Maybe User.Model -> Nav.Key -> ( Model, Cmd Msg )
init user key =
  ( Model key 
    (Carousel.init (Array.fromList [ "./src/img/1.jpg", "./src/img/2.jpg", "./src/img/3.jpg", "./src/img/4.jpg" ]))
     user
     , Cmd.none 
  )

update: Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    UpdateCarousel mesg -> 
       ({ model | carousel = Carousel.update mesg model.carousel }, Cmd.none)

view: Model -> Html Msg
view model =
  let
    url = "url(" ++ Server.url ++ "/img/background.jpg"  ++ ")"
  in
    div [ style "text-align" "center" ][
      div [][ Carousel.view model.carousel |> Html.map UpdateCarousel ]
      , h3 [ class "lead"
      , style "font-size" "30px" ][
        text "Welcome to Elm Gallery" 
      ]
      , div [ class "help-block"
      , style "margin-top" "-20px" ][
        text "Single page web application created as a school project"
      ]
      , div [ class "row", style "margin-top" "100px" ][]
    ]


subscriptions : Model -> Sub Msg
subscriptions model =
  Carousel.subscriptions model.carousel |> Sub.map UpdateCarousel
