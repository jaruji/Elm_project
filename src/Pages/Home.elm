module Pages.Home exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Browser.Navigation as Nav
import Components.Carousel as Carousel
import User
import Server
import Http
import Image
import Tag
import Time
import TimeFormat
import Json.Decode as Decode
import Array exposing (..)
import FeatherIcons as Icons
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)

{--
  Homepage contains the Carousel component. It also shows the last 5 posts that were uploaded
  to the app and a list of most popular tags. Every 30 seconds, latest posts and tags update through
  subscription (after 30s the request to obtain tags and posts are re-sent).
--}

type alias Model =
  {
    key: Nav.Key
    , carousel: Carousel.Model
    , user: Maybe User.Model
    , status: Status
    , tagStatus: TagsStatus
  } 


type Msg
  = UpdateCarousel Carousel.Msg
  | Response (Result Http.Error (List Image.Preview))
  | TagsResponse (Result Http.Error (List String))
  | Reload

type Status
  = Loading
  | Success (List Image.Preview)
  | Failure

type TagsStatus
  = LoadingTags
  | SuccessTags (List String)
  | FailureTags

init: Maybe User.Model -> Nav.Key -> ( Model, Cmd Msg )
init user key =
  ( 
    Model key (Carousel.init (Array.fromList [ "assets/carousel/1.jpg"
                                            , "assets/carousel/2.jpg"
                                            , "assets/carousel/3.jpg"
                                            , "assets/carousel/4.jpg"
                                            , "assets/carousel/5.jpg"
                                            , "assets/carousel/6.jpg" ]))
    user Loading LoadingTags, Cmd.batch[ getLatest, getTrending ]
  )

update: Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    UpdateCarousel mesg -> 
      --because Carousel does not use Cmd, we can convert the it Carousel.Model to Model like this
       ({ model | carousel = Carousel.update mesg model.carousel }, Cmd.none)

    Response response ->
      case response of
        Ok images ->
          ({ model | status = Success images }, Cmd.none)
        Err log ->
          ({ model | status = Failure }, Cmd.none)

    TagsResponse response ->
      case response of
        Ok tags ->
          ({ model | tagStatus = SuccessTags tags }, Cmd.none)
        Err log ->
          ({ model | tagStatus = FailureTags }, Cmd.none)

    Reload ->
      --update latest posts and tags simultaneously
      (model, Cmd.batch[ getLatest, getTrending ])

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
          --text on page is different based on if user is logged in or not
          Just user ->
            div[][]
          Nothing ->
            a [ href "/sign_up" ] [ button [ class "btn btn-lg btn-default" ][
              h4 [] [ text "Get started" ] ]
            ]
      ]
      , div[ style "margin-top" "470px" ][
        div [ style "margin-bottom" "20px" ][
          h2 [] [ text "Trending tags" ]
          , div [ class "help-block" ] [ text "Overview of trending tags" ]
          , hr [ style "width" "50%" 
          , style "margin" "auto" 
          , style "margin-bottom" "20px" ] []
          , case model.tagStatus of
            LoadingTags ->
              div[ style "margin-top" "20px" ][
                Loader.render Loader.Circle {defaultConfig | size = 60} Loader.On
              ]
            FailureTags ->
              div [ class "alert alert-warning"
              , style "width" "50%" 
              , style "margin" "auto" 
              , style "margin-top" "20px" ][ text "Connection error"]
            SuccessTags tags ->
              div [ class "well"
              , style "width" "50%"
              , style "margin" "auto" ] (List.map Tag.view tags)
          , h2 [] [ text "Latest posts" ]
          , div [ class "help-block" ] [ text "Overview of latest images posted to the site" ]
          , hr [ style "width" "70%" 
          , style "margin" "auto" 
          , style "margin-bottom" "20px" ] []
          , case model.status of
            Loading ->
              div[ style "margin-top" "20px" ][
                Loader.render Loader.Circle {defaultConfig | size = 60} Loader.On
              ]
            Failure ->
              div [ class "alert alert-warning"
              , style "width" "50%" 
              , style "margin" "auto" 
              , style "margin-top" "20px" ][ text "Connection error"]
            Success images ->
              div[][
                div [] ( List.map showPost images )
              ]
        ]
      ]
    ]

showPost: Image.Preview -> Html Msg
showPost post =
    --show post which is used with List.map to show latest posts
    div[ class "media"
    , style "width" "70%"
    , style "margin" "auto"
    , style "margin-bottom" "20px"  ][
        div[ class "media-left" ][
            a [ href ("/post/" ++ post.id) ][
                img [ src post.url
                , class "avatar"
                , attribute "draggable" "false"
                , height 170
                , width 170 ][]
            ]
        ]
        , div[ class "media-body well"
        , style "text-align" "center" ][
            div [ class "media-heading" ][
                div [] [
                    a [ href ("/post/" ++ post.id), class "preview" ][ 
                      h4 [] [ text post.title ] 
                    ]
                ]
            ]
            , div [ class "media-body" ][
              div[ class "help-block" ][
                  h5 [] [ text ( "Uploaded on " ++ TimeFormat.formatDate post.uploaded ) ]
                  , h6 [] [
                    text ("by ")
                    , a [ href ("/profile/" ++ post.author), class "preview" ][
                      text post.author
                    ] 
                  ]
                  , h5 [] [ text ( String.fromInt post.views ++ " views" ) ]
                ]
            ]
        ]
    ]

getLatest: Cmd Msg
getLatest =
  Http.get{
    url = Server.url ++ "/posts/latest"
    , expect = Http.expectJson Response (Decode.list Image.decodePreview)
  }

getTrending: Cmd Msg
getTrending =
  Http.get{
    url = Server.url ++ "/tags/trending"
    , expect = Http.expectJson TagsResponse (Decode.list Decode.string)
  }

subscriptions : Model -> Sub Msg
subscriptions model =
  --Use the subscription of Carousel component and additionaly every 30s reload tags and posts
  Sub.batch[ 
    Carousel.subscriptions model.carousel |> Sub.map UpdateCarousel
    , Time.every 30000 (\_ ->
      (
        Reload
      )
    )
  ]
