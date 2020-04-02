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
      , div [ class "container-fluid" ][
        div [ class "row" ][
          div [ class "col-sm-4 col-md-4 col-lg-4" ][
            h3 [ class "lead"
            , style "font-size" "30px" ][
              span [ style "margin-right" "10px", style "color" "#00acee" ] [ Icons.user |> Icons.withSize 40 |> Icons.withStrokeWidth 3 |> Icons.toHtml [] ] 
              , text "Create a Profile" 
            ]
            , p [ class "help-block" ] [ text "On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the charms of pleasure of the moment, so blinded by desire, that they cannot foresee the pain and trouble that are bound to ensue; and equal blame belongs to those who fail in their duty through weakness of will, which is the same as saying through shrinking from toil and pain. These cases are perfectly simple and easy to distinguish. In a free hour, when our power of choice is untrammelled and when nothing prevents our being able to do what we like best, every pleasure is to be welcomed and every pain avoided. But in certain circumstances and owing to the claims of duty or the obligations of business it will frequently occur that pleasures have to be repudiated and annoyances accepted. The wise man therefore always holds in these matters to this principle of selection: he rejects pleasures to secure other greater pleasures, or else he endures pains to avoid worse pains." ]
          ]
          , div [ class "col-sm-4 col-md-4 col-lg-4" ] [
            h3 [ class "lead"
            , style "font-size" "30px" ][
              span [ style "margin-right" "10px", style "color" "#00acee" ] [ Icons.logIn |> Icons.withSize 40 |> Icons.withStrokeWidth 3 |> Icons.toHtml [] ] 
              , text "Sign In" 
            ]
            , p [ class "help-block" ] [ text "On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the charms of pleasure of the moment, so blinded by desire, that they cannot foresee the pain and trouble that are bound to ensue; and equal blame belongs to those who fail in their duty through weakness of will, which is the same as saying through shrinking from toil and pain. These cases are perfectly simple and easy to distinguish. In a free hour, when our power of choice is untrammelled and when nothing prevents our being able to do what we like best, every pleasure is to be welcomed and every pain avoided. But in certain circumstances and owing to the claims of duty or the obligations of business it will frequently occur that pleasures have to be repudiated and annoyances accepted. The wise man therefore always holds in these matters to this principle of selection: he rejects pleasures to secure other greater pleasures, or else he endures pains to avoid worse pains." ]
          ]
          , div [ class "col-sm-4 col-md-4 col-lg-4" ] [
            h3 [ class "lead"
            , style "font-size" "30px" ][
              span [ style "margin-right" "10px", style "color" "#00acee" ] [ Icons.sliders |> Icons.withSize 40 |> Icons.withStrokeWidth 3 |> Icons.toHtml [] ] 
              , text "Personalize your profile" 
            ]
            , p [ class "help-block" ] [ text "On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the charms of pleasure of the moment, so blinded by desire, that they cannot foresee the pain and trouble that are bound to ensue; and equal blame belongs to those who fail in their duty through weakness of will, which is the same as saying through shrinking from toil and pain. These cases are perfectly simple and easy to distinguish. In a free hour, when our power of choice is untrammelled and when nothing prevents our being able to do what we like best, every pleasure is to be welcomed and every pain avoided. But in certain circumstances and owing to the claims of duty or the obligations of business it will frequently occur that pleasures have to be repudiated and annoyances accepted. The wise man therefore always holds in these matters to this principle of selection: he rejects pleasures to secure other greater pleasures, or else he endures pains to avoid worse pains." ]
          ]
        ]
        , div [ class "row" ][
          div [ class "col-sm-4 col-md-4 col-lg-4" ][
            h3 [ class "lead"
            , style "font-size" "30px" ][
              span [ style "margin-right" "10px", style "color" "#00acee" ] [ Icons.upload |> Icons.withSize 40 |> Icons.withStrokeWidth 3 |> Icons.toHtml [] ] 
              , text "Upload Images" 
            ]
            , p [ class "help-block" ] [ text "On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the charms of pleasure of the moment, so blinded by desire, that they cannot foresee the pain and trouble that are bound to ensue; and equal blame belongs to those who fail in their duty through weakness of will, which is the same as saying through shrinking from toil and pain. These cases are perfectly simple and easy to distinguish. In a free hour, when our power of choice is untrammelled and when nothing prevents our being able to do what we like best, every pleasure is to be welcomed and every pain avoided. But in certain circumstances and owing to the claims of duty or the obligations of business it will frequently occur that pleasures have to be repudiated and annoyances accepted. The wise man therefore always holds in these matters to this principle of selection: he rejects pleasures to secure other greater pleasures, or else he endures pains to avoid worse pains." ]
          ]
          , div [ class "col-sm-4 col-md-4 col-lg-4" ] [
            h3 [ class "lead"
            , style "font-size" "30px" ][
              span [ style "margin-right" "10px", style "color" "#00acee" ] [ Icons.image |> Icons.withSize 40 |> Icons.withStrokeWidth 3 |> Icons.toHtml [] ] 
              , text "Browse our Gallery" 
            ]
            , p [ class "help-block" ] [ text "On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the charms of pleasure of the moment, so blinded by desire, that they cannot foresee the pain and trouble that are bound to ensue; and equal blame belongs to those who fail in their duty through weakness of will, which is the same as saying through shrinking from toil and pain. These cases are perfectly simple and easy to distinguish. In a free hour, when our power of choice is untrammelled and when nothing prevents our being able to do what we like best, every pleasure is to be welcomed and every pain avoided. But in certain circumstances and owing to the claims of duty or the obligations of business it will frequently occur that pleasures have to be repudiated and annoyances accepted. The wise man therefore always holds in these matters to this principle of selection: he rejects pleasures to secure other greater pleasures, or else he endures pains to avoid worse pains." ]
          ]
          , div [ class "col-sm-4 col-md-4 col-lg-4" ] [
            h3 [ class "lead"
            , style "font-size" "30px" ][
              span [ style "margin-right" "10px", style "color" "#00acee" ] [ Icons.thumbsUp |> Icons.withSize 40 |> Icons.withStrokeWidth 3 |> Icons.toHtml [] ] 
              , text "Rate and Comment" 
            ]
            , p [ class "help-block" ] [ text "On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the charms of pleasure of the moment, so blinded by desire, that they cannot foresee the pain and trouble that are bound to ensue; and equal blame belongs to those who fail in their duty through weakness of will, which is the same as saying through shrinking from toil and pain. These cases are perfectly simple and easy to distinguish. In a free hour, when our power of choice is untrammelled and when nothing prevents our being able to do what we like best, every pleasure is to be welcomed and every pain avoided. But in certain circumstances and owing to the claims of duty or the obligations of business it will frequently occur that pleasures have to be repudiated and annoyances accepted. The wise man therefore always holds in these matters to this principle of selection: he rejects pleasures to secure other greater pleasures, or else he endures pains to avoid worse pains." ]
          ]
          , div [ class "row", style "margin-bottom" "60px" ][] 
        ]
      ]
    ]


subscriptions : Model -> Sub Msg
subscriptions model =
  Carousel.subscriptions model.carousel |> Sub.map UpdateCarousel
