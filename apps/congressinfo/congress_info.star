"""
Applet: Congress Info
Summary: Show Congress Information
Description: This app will show the latest information from congress using congress.gov. This includes new bills, actions on bills, etc.
Author: Anders Heie
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("qrcode.star", "qrcode")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

# Global defines

# Each API key has a limit of 1000 calls per day, so we limit requests accordingly
# from `pixlet encrypt`
ENCRYPTED_API_KEY = "AV6+xWcElUzvZN/dhFNsUKBn23nB5ve0BFAg7K+KXpUnTwLDBM6SI8Z4UfhbKMHS8D9rhznOavGujoBnF1ou0svTK3WQmnrR4hYlOTNibJicWHiNUGnAU0eqMLi65kjQ77WXjrbKTh5URKBr7xKYkA6UGXrozOCYqS7NB/7N4Ler7NGugFfYrA5kWN0XXQ=="


CONGRESS_BILL_URL = "https://api.congress.gov/v3/bill"
BILLS_CACHE_KEY = "congress_info_app_bills"
BILL_CACHE_TIME = 60

CONGRESS_MEMBER_URL = "https://api.congress.gov/v3/member"
MEMBERS_CACHE_KEY = "congress_info_app_members"
MEMBERS_CACHE_TIME = 60

DEFAULT_COLOR = "#0000FF"


def main(config):
    #  Oh Joy: When you run pixlet locally, secret.decrypt will always return None. When your app runs in the Tidbyt cloud, secret.decrypt will return the string that you passed to pixlet encrypt.
    api_key = secret.decrypt(
        ENCRYPTED_API_KEY) or "KgvV3dODgZ0ZQgfvDL3hcbQ9okRgnX08Us0nHQiS"

    #  Settings
    #    - Include Bills
    #      - With keyword:
    #    include ammendments
    #      - with keyword
    #    include new congress people
    #      - with keyword
    #    include committee reports
    #      - with keywords
    #    Include QR-Codes for congressional records?
    #      - can we make QR codes for PDF's?

    #   if more than one included, randomize results

    # Cycle through the info, picking all content that is the Same data as the newest date found

    # Create unique cache key based on config values.
    # The only one that really matters for now is the number of participants
    includeBills = config.get("bills", True)
    latestBill = getBills(api_key)
    numberOfBills = len(latestBill["bills"])
    randomBill = random.number(0, numberOfBills - 1)
    print("Bills: " + str(len(latestBill["bills"])) +
          " - First one: " + str(latestBill["bills"][randomBill]))

    includeMembers = config.get("members", False)
    latestMembers = getMembers(api_key)
    numberOfMembers = len(latestMembers["members"])
    randomMember = random.number(0, numberOfMembers - 1)
    print("Members: " + str(len(latestMembers["members"])) +
          " - First one: " + str(latestMembers["members"][randomMember]))

    code = qrcode.generate(
        url="https://tinyurl.com/5n6t8b29",
        size="large",
        color="#fff",
        background="#000",
    )

    # Perform some content jui-jitsu to clean up government references
    # remove (text: ...)
    # change <p> into new lines
    # lowercase first character of latestAction.text
    # Change date to text (using widget I think)

    color = config.get("color", DEFAULT_COLOR)

    child = render.Box(
        render.Marquee(
            height=32,
            child=render.WrappedText(
                content=latestBill["bills"][randomBill]["latestAction"]["actionDate"] + ":\n" +
                latestBill["bills"][randomBill]["title"] + " was " +
                latestBill["bills"][randomBill]["latestAction"]["text"] +
                "\n-------------\n" +
                latestMembers["members"][randomMember]["name"] + "\n" +
                latestMembers["members"][randomMember]["state"] + "\n" +
                latestMembers["members"][randomMember]["party"],
                color=color,
                width=64,
                align="left",
            ),
            offset_start=16,
            offset_end=16,
            scroll_direction="vertical",
        ),

        #        render.Padding(
        #            child=render.Image(src=code),
        #            pad=1,
        #        )
    )

    child = render.Marquee(
        height=32,
        child=render.Column(
            children=[
                render.WrappedText(
                    content=latestBill["bills"][randomBill]["latestAction"]["actionDate"] + ":\n" +
                    latestBill["bills"][randomBill]["title"] + " was " +
                    latestBill["bills"][randomBill]["latestAction"]["text"] +
                    "\n-------------\n" +
                    latestMembers["members"][randomMember]["name"] + "\n" +
                    latestMembers["members"][randomMember]["state"] + "\n" +
                    latestMembers["members"][randomMember]["party"],
                    color=color,
                    width=64,
                    align="left",
                ),
                render.Padding(
                    child=render.Image(src=code),
                    pad=1,
                ),
            ],
            # expanded=True
        ),
        offset_start=16,
        offset_end=16,
        scroll_direction="vertical",
    )

    child = render.Column(
        children=[
            # render.Stack(
            # children=[
            render.Text(
                content="Congress",
                color=color,
            ),
            render.Row(
                children=[
                    render.Box(
                        width=1,
                        height=1,
                        color="#222200",
                    ),
                    render.Box(
                        width=1,
                        height=1,
                        color="#444400",
                    ),
                    render.Box(
                        width=1,
                        height=1,
                        color="#aa6600",
                    ),
                    render.Box(
                        width=2,
                        height=1,
                        color="#FF8800",
                    ),
                    render.Box(
                        width=32,
                        height=1,
                        color="#FF0000",
                    ),
                    render.Box(
                        width=2,
                        height=1,
                        color="#FF8800",
                    ),
                    render.Box(
                        width=1,
                        height=1,
                        color="#aa6600",
                    ),
                    render.Box(
                        width=1,
                        height=1,
                        color="#444400",
                    ),
                    render.Box(
                        width=1,
                        height=1,
                        color="#222200",
                    ),
                ],
                main_align="center",
                expanded=True,
            ),
            #           render.Stack(
            #              children=[
            #                  animation.Transformation(
            #                      child=render.Box(render.Circle(
            #                          diameter=3, color="#0f0")),
            #                      duration=10,
            #                      delay=0,
            #                      height=10,
            #                      origin=animation.Origin(0.5, 0.5),
            #                      direction="alternate",
            #                      fill_mode="forwards",
            #                      keyframes=[
            #                          animation.Keyframe(
            #                              percentage=0.0,
            #                              transforms=[animation.Rotate(
            #                                  0), animation.Translate(-1, 0), animation.Rotate(0)],
            #                              curve="ease_in_out",
            #                          ),
            #                          animation.Keyframe(
            #                              percentage=1.0,
            #                              transforms=[animation.Rotate(
            #                                  360), animation.Translate(-1, 0), animation.Rotate(-360)],
            #                          ),
            #                      ],
            #                  ),
            #                  animation.Transformation(
            #                      child=render.Box(render.Circle(
            #                          diameter=4, color="#f00")),
            #                      duration=10,
            #                      delay=0,
            #                      height=10,
            #                      origin=animation.Origin(0, 0.1),
            #                      direction="alternate",
            #                      fill_mode="backwards",
            #                      keyframes=[
            #                          animation.Keyframe(
            #                              percentage=0.0,
            #                              transforms=[animation.Rotate(
            #                                  0), animation.Translate(-1, 0), animation.Rotate(0)],
            #                              curve="ease_in_out",
            #                          ),
            #                          animation.Keyframe(
            #                              percentage=1.0,
            #                              transforms=[animation.Rotate(
            #                                  360), animation.Translate(-1, 0), animation.Rotate(-360)],
            #                          ),
            #                      ],
            #                  ),

            #              ],
            #          ),
            animation.Transformation(
                child=render.Box(render.Circle(
                    diameter=2, color="#fff")),
                duration=10,
                delay=0,
                height=3,
                width=32,
                origin=animation.Origin(0.5, 0.5),
                direction="alternate",
                fill_mode="forwards",
                keyframes=[
                    animation.Keyframe(
                        percentage=0.0,
                        transforms=[animation.Translate(30, 0)],
                        curve="ease_in_out",
                    )
                ],
            ),
            # ]
            # )
        ],
    )

    return render.Root(
        child,
        show_full_animation=bool(config.get("scroll", True)),
        delay=45,
    )


def getBills(api_key):
    x = cache.get(BILLS_CACHE_KEY)

    if x != None:
        print("Hit! Displaying cached bill data.")
        latestBill = json.decode(x)
    else:
        print("Miss! Calling Congress.gov API for bills list.")
        params = {
            "api_key": api_key,
        }

        # if includeBills == True:
        rep = http.get(CONGRESS_BILL_URL, params=params)

        if rep.status_code != 200:
            # if the APi fails, return [] to skip this app showing
            fail("API request failed with status %d", rep.status_code)

        latestBill = rep.json()
        cache.set(BILLS_CACHE_KEY, json.encode(
            latestBill,
        ), ttl_seconds=BILL_CACHE_TIME)

    return latestBill


def getMembers(api_key):
    x = cache.get(MEMBERS_CACHE_KEY)

    if x != None:
        print("Hit! Displaying cached member data.")
        latestMembers = json.decode(x)
    else:
        print("Miss! Calling Congress.gov API for members list.")
        params = {
            "api_key": api_key,
        }

        # if includeBills == True:
        rep = http.get(CONGRESS_MEMBER_URL, params=params)

        if rep.status_code != 200:
            # if the APi fails, return [] to skip this app showing
            fail("API request failed with status %d", rep.status_code)

        latestMembers = rep.json()
        cache.set(MEMBERS_CACHE_KEY, json.encode(
            latestMembers,
        ), ttl_seconds=MEMBERS_CACHE_TIME)

    return latestMembers


def get_schema():
    color_options = [
        schema.Option(
            display="Pink",
            value="#FF94FF",
        ),
        schema.Option(
            display="Mustard",
            value="#FFD10D",
        ),
        schema.Option(
            display="Blue",
            value="#0000FF",
        ),
        schema.Option(
            display="Red",
            value="#FF0000",
        ),
        schema.Option(
            display="Green",
            value="#00FF00",
        ),
        schema.Option(
            display="Purple",
            value="#FF00FF",
        ),
        schema.Option(
            display="Cyan",
            value="#00FFFF",
        ),
        schema.Option(
            display="White",
            value="#FFFFFF",
        ),
    ]

    speed_options = [
        schema.Option(
            display="Slow Scroll",
            value="60",
        ),
        schema.Option(
            display="Medium Scroll",
            value="45",
        ),
        schema.Option(
            display="Fast Scroll",
            value="30",
        ),
    ]

    return schema.Schema(
        version="1",
        fields=[
            schema.Toggle(
                id="scroll",
                name="Scroll until the end",
                desc="Keep scrolling text even if it's longer than app-rotation time",
                icon="user",
                default=True,
            ),
            schema.Dropdown(
                id="speed",
                name="Scroll Speed",
                desc="Scrolling speed",
                icon="gear",
                default=speed_options[1].value,
                options=speed_options,
            ),
            schema.Toggle(
                id="bills",
                name="Include bills",
                desc="Shows actions taken on bills in congress",
                icon="user",
                default=True,
            ),
            schema.Toggle(
                id="executive_orders",
                name="Executive Orders",
                desc="Show executive orders",
                icon="user",
                default=True,
            ),
            schema.Toggle(
                id="members",
                name="Include members",
                desc="Show a random member of congress",
                icon="user",
                default=False,
            ),
            schema.Dropdown(
                id="color",
                name="Text Color",
                desc="The color of text to be displayed.",
                icon="brush",
                default=color_options[0].value,
                options=color_options,
            ),
        ],
    )
