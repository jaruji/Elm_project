module Pages.Home exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Browser.Navigation as Nav
import Components.Carousel as Carousel


type alias Model =
  {
    key: Nav.Key,
    carousel: Carousel.Model
  } 

type Msg
  = UpdateCarousel Carousel.Msg

init: Nav.Key -> ( Model, Cmd Msg )
init key =
  ( Model key Carousel.init, Cmd.none )

update: Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    UpdateCarousel mesg -> 
       ({ model | carousel = Carousel.update mesg model.carousel }, Cmd.none)

view: Model -> Html Msg
view model =
  div [ ] [
    div [ class "container-fluid text-center", style "height" "800px" ][
      h1 [ style "margin-top" "100px" ] [ text "Welcome to my website" ]
    ]
    , div [][ Carousel.view model.carousel |> Html.map UpdateCarousel ]
  {--
    div [ class "jumbotron"
          , style "height" "1000px" 
          , style "text-align" "center"
          , style "padding-top" "100px" 
          , style "width" "100%" ][
            h1 [][ text "Welcome to my website"]
            , p [] [ text "Powered by Elm. This website was created as a project for my bachelor's thesis" ]
    ]
    --}
  ]


subscriptions : Model -> Sub Msg
subscriptions model =
  Carousel.subscriptions model.carousel |> Sub.map UpdateCarousel
 