"""
Applet: Enphase Solar
Summary: Solar energy monitor
Description: Display energy generated by solar panels based on Enlighten API v4.
Author: laodaochong
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("hash.star", "hash")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

TITLE_TEXT_COLOR = "#fff"
TITLE_BKG_COLOR = "#ff0000aa"
TITLE_FONT = "tom-thumb"
TITLE_HEIGHT = 8
TITLE_WIDTH = 64
AREA_HEIGHT = 24

ENDPOINT = "https://api.enphaseenergy.com/api/v4/systems"
AUTH_URL = "https://api.enphaseenergy.com/oauth/token"
EXPIRE_MSG = "Access token has expired"
ACCESS_TOKEN_KEY = "access_token_{}"
REFRESH_TOKEN_KEY = "refresh_token_{}"
ENERGY_TODAY_KEY = "energy_today_{}"
INIT_KEY = "init_{}"

SCROLL_MSG_LEN = 36

# Due to limited number of API calls in free version of Enphase Application, here it only update
# information every hour.
TTL_SECONDS = 3600

def check_response(response):
    if response.status_code == 200:
        return 200, response.json()
    elif response.status_code == 401 and EXPIRE_MSG in response.json().get("details"):
        print("Access token is expired and refresh token now. Call next time.")
        return 401, None
    else:
        print("Request is failed with status code {} {}".format(response.status_code, response.json()))
        return response.status_code, None

def get_system_stats(api_key, unique_suffix):
    headers = {
        "Authorization": "Bearer " + cache.get(ACCESS_TOKEN_KEY.format(unique_suffix)),
        "Content-Type": "application/json",
    }

    params = {
        "key": api_key,
    }

    response = http.get(ENDPOINT, params = params, headers = headers)

    status, result = check_response(response)

    if status == 200 and result:
        return 200, str(result["systems"][0]["energy_today"])
    elif status == 401:
        return 401, None
    else:
        msg = "No result returned."
        return status, msg

def request_refresh_token(refresh_token_code, client_id, client_secret):
    encoded_client_secrets = base64.encode("{}:{}".format(client_id, client_secret))
    unique_suffix = hash.md5(client_id)

    headers = {
        "Authorization": "Basic {}".format(encoded_client_secrets),
        "Content-Type": "application/json",
    }
    params = {
        "grant_type": "refresh_token",
        "refresh_token": refresh_token_code,
    }

    response = http.post(AUTH_URL, params = params, headers = headers)
    if response.status_code == 200:
        print("Refresh token successfully.")

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(
            ACCESS_TOKEN_KEY.format(unique_suffix),
            response.json()["access_token"],
            ttl_seconds = int(response.json()["expires_in"]),
        )

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(
            REFRESH_TOKEN_KEY.format(unique_suffix),
            response.json()["refresh_token"],
            ttl_seconds = int(response.json()["expires_in"]) * 7,
        )
    else:
        msg = "Refresh token failed with status code {}, message {}".format(
            response.status_code,
            response.json(),
        )
        render_msg(msg)

def format_msg(msg):
    return render.WrappedText(
        content = msg,
        width = 50,
        color = "#fa0",
    )

def render_information(msg, scroll = False):
    if scroll:
        return render.Marquee(
            height = AREA_HEIGHT,
            scroll_direction = "vertical",
            offset_start = 24,
            child =
                render.Column(
                    main_align = "space_between",
                    children = ([format_msg(msg)]),
                ),
        )
    return format_msg(msg)

def render_msg(msg):
    """Render message to App"""
    scroll = len(msg) > SCROLL_MSG_LEN
    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = TITLE_WIDTH,
                    height = TITLE_HEIGHT,
                    padding = 0,
                    color = TITLE_BKG_COLOR,
                    child = render.Text("Solar Energy", color = TITLE_TEXT_COLOR, font = TITLE_FONT, offset = 0),
                ),
                render_information(msg, scroll),
            ],
        ),
    )

def main(config):
    """Display Energy produced by solar panels daily basis."""
    if not config.bool("switch", True):
        return render_msg("Switch is off, so take a rest.")

    access_token = config.str("access_token")
    refresh_token = config.str("refresh_token")
    client_id = config.str("client_id")
    client_secret = config.str("client_secret")
    api_key = config.str("api_key")
    unique_suffix = hash.md5(client_id)

    if not all([access_token, refresh_token, client_id, client_secret, api_key]):
        msg = "Missing credential information. In order to show number of kWh energy generated everyday, please provide Access Token, Refresh Token, Client ID, Client Secret and API Key in the App Configuration."
        return render_msg(msg)

    # check if it is initial invocation by check "init" flag in the cache
    init = cache.get(INIT_KEY.format(unique_suffix))
    if init == None:
        # Cache is scoped to the app, not individual user. So the cache keys need to be
        # unique to the user/configuration

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(
            ACCESS_TOKEN_KEY.format(unique_suffix),
            access_token,
            ttl_seconds = TTL_SECONDS,
        )

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(
            REFRESH_TOKEN_KEY.format(unique_suffix),
            refresh_token,
            ttl_seconds = TTL_SECONDS * 7,
        )

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(INIT_KEY.format(unique_suffix), "1")

    # check access token if it needs to be refreshed
    access_token = cache.get(ACCESS_TOKEN_KEY.format(unique_suffix))
    if access_token == None:
        request_refresh_token(cache.get(REFRESH_TOKEN_KEY.format(unique_suffix)), client_id, client_secret)

    # Get "energy_today"
    engery_cached = cache.get(ENERGY_TODAY_KEY.format(unique_suffix))
    if engery_cached == None:
        status, energy_today = get_system_stats(api_key, unique_suffix)
        if status == 200:
            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set(
                ENERGY_TODAY_KEY.format(unique_suffix),
                energy_today,
                ttl_seconds = TTL_SECONDS,
            )
        elif status == 401:
            request_refresh_token(cache.get(REFRESH_TOKEN_KEY.format(unique_suffix)), client_id, client_secret)
            return render_msg("Token just refreshed wait for next call.")
        else:
            return render_msg("Unable to get system stats, status code: {}".format(status))
    else:
        print("Hit! Displaying cached data.")
        energy_today = engery_cached

    msg = "{} kWh energy generated today".format(humanize.float("#.##", float(energy_today) / 1000))
    return render_msg(msg)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "switch",
                name = "Switch On/Off",
                desc = "Switch the app on or off",
                icon = "gear",
                default = False,
            ),
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "API key for the Enphase API. Follow https://developer-v4.enphase.com/docs/quickstart.html#create_account.",
                icon = "key",
            ),
            schema.Text(
                id = "client_id",
                name = "Client ID",
                desc = "The client id of Enphase application",
                icon = "key",
            ),
            schema.Text(
                id = "client_secret",
                name = "Client Secret",
                desc = "The client secret of Enphase application",
                icon = "key",
            ),
            schema.Text(
                id = "access_token",
                name = "Access Token",
                desc = "Access token to allow App read information via Enphase API.",
                icon = "key",
            ),
            schema.Text(
                id = "refresh_token",
                name = "Refresh Token",
                desc = "Refresh token used to refresh access token when it is expired.",
                icon = "key",
            ),
        ],
    )
