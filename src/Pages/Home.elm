module Pages.Home exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Browser.Navigation as Nav
import Components.Carousel as Carousel
import User


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
  ( Model key Carousel.init user, Cmd.none )

update: Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    UpdateCarousel mesg -> 
       ({ model | carousel = Carousel.update mesg model.carousel }, Cmd.none)

view: Model -> Html Msg
view model =
  div [ ] [
    div [ class "container-fluid text-center", style "height" "800px" ][
      case model.user of
        Just user ->
          h1 [ style "margin-top" "100px" ] [ text ("Welcome, " ++ user.username) ]
        Nothing ->
          h1 [ style "margin-top" "100px" ] [ text "Welcome to our Website" ]
    ]
    --, div [][ Carousel.view model.carousel |> Html.map UpdateCarousel ]
  ]

{--
subscriptions : Model -> Sub Msg
subscriptions model =
  Carousel.subscriptions model.carousel |> Sub.map UpdateCarousel
--} 