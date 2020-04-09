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
    (Carousel.init (Array.fromList [ "assets/1.jpg", "assets/2.jpg", "assets/3.jpg", "assets/4.jpg" ]))
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
      , div [ style "margin-top" "-600px"
      , style "width" "50%"
      , style "margin-left" "25%" ][
        h1 [ class "lead"
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
        , case model.user of
          Just user ->
            div[][]
          Nothing ->
            a [ href "/sign_up" ] [ button [ class "btn btn-lg btn-default" ][
              h4 [] [ text "Get started" ] ]
            ]
      ]
      , div[ style "margin-top" "470px" ][
        h3 [ class "lead"
        , style "font-size" "30px" ][
          text "Welcome to Elm Gallery" 
        ]
        , div [ class "help-block"
        , style "margin-top" "-20px" ][
          text "Single page web application created as a school project"
        ]
        , div [ class "jumbotron", style "margin-bottom" "-20px" ][
          h2 [] [ text "Get started" ]
        ]
      ]
    ]


subscriptions : Model -> Sub Msg
subscriptions model =
  Carousel.subscriptions model.carousel |> Sub.map UpdateCarousel
