"""
Applet: Congress Info
Summary: Show Congress Information
Description: This app will show the latest information from congress using congress.gov. This includes new bills, actions on bills, etc.
Author: Anders Heie
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("qrcode.star", "qrcode")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

# Remember to go and vote. Voting matters !

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
DEFAULT_BACK_COLOR = "#000000"

REPUBLICAN_ICON = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAcCAMAAAA3HE0QAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAACLlBMVEUAAAAOALgVBbsTA74UA7wUBb4VA74WBL4TBrscAMYTBL0UA74UA70UBL0VBL0UBL4UALoUBL0UBL0UBL4AAMwUA7waCr8UBL0gAL8RBr8UBL0VBL0UBL0QAL0XBrsUBb0UBb0TBLwTBL0UBL0UA70VBL0TA70UBL0UBL0UA70UBL0UBL0UA73iAADdAADeAADeAADfAADdAADdAgDeAQDeAgDeAQDeAgDeAQDeAQDeAgDeAQDfAgDeAQDdAQDeAQDdAgDeAQDfAADeAQDdAgDfAQDdAADhAADeAADeAQDeAQD/AADfAADdAADeAgDeAgDdAADeAQDeAgC/AADeAgDeAADeAgDeAQDfAADfAADeAgDgAADeAgDeAgDfAADjAADeAQDeAQDeAQDeAgDfAgDeAADeAQDfAADgAADeAQDeAQDeAQDeAQDdAADdAADeAgDeAADmAADeAQDeAQDeAAD/AADhAADgAADoAAAUBL0VBb0aC78cDb8ZCb6yrOksHsRVSc98c9pqYNUnGcKwqukbDL8mF8KuqOgkFcFrYdVvZderpefx8Pv+/v9JPMw9MMn////08/zCvu7w7/sxI8U5K8fW1PSRiuAYCL6TjOHd2/VAM8lFOMvi3/f9/f6Ad9smGMKWj+Ghm+X39v3Oy/FsYtZdUtHDv+749/2Kgt4lFsIvIcWbleOjneXFwe9eU9KzrepNQc1GOcu3suvKx/A4KsdSRs4XB75QRM7eAQA4LC0+AAAAeXRSTlMAEjFPW2ZWRykJQpzb+8aBGs34jQVY97wILPWHyB8tcGi4g9Wb7J702N3UzJoaU1VdZkSP65PylPT2lfiW+q79l90Q+ZjMJiJ039ACVy2ZpDXgoQSETqPiZyioMpqiNxv8++mbnTbZblG6u8LHSg+qYwqr/nwBESkLc0FZcgAAAAFiS0dEkHgKjgwAAAAHdElNRQfmBBULFiXFR90jAAABpElEQVQoz2NggAFGJmYWVlZWNnYOTgZMwMXNUwkHvHz8AqjSTIKVaEBIWARJXlSsqrKyGihcU1lZVQ1hVotLwOUlpWrr6hsagaKNTc0trZWVbe0dnV2V0nAFMpWV3T29fUAF/RMm1oEsmDR5wpRKXlmovFxl5dRpEyZMn1FZO3PChFmzKyvnzJ0wb35VpTxUgULlgoWLFi9ZtLRy2fTlK6avXLV6zdredYvWVypCFSiBDN2wEez4TZshntiyFUgoQxWogES2bQdLVO2AKGgAEapQBWqVOIA6VAGLhiYG0NIGAh2oAl09fSAwMMQARlAFxjtxABOoAlNcCsygCsxxKbAgpMASqsAKlwJrqAIbXAps8SiwtAMS9lAFDlgUODo5A0moAhewkKubOxh4gHmeDF5A0tvH1dWXgcEPLOQPVR4A5gUyBAHJ4JCdO0NhCsJQFIQzRADJyKidO6MZGGLAQrFQBXFQBfEJO3cm7tyZFMzAkAwWSoEqSAXz0hgYUsCMdKBQRmZWVnZOLlRBXn5WVn5+AQNDYVHxTsuSUgY8oKy8AkgCAGJtUkXJZhDyAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDIyLTA0LTIxVDExOjIyOjM3KzAwOjAw5tjLpAAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyMi0wNC0yMVQxMToyMjozNyswMDowMJeFcxgAAAAASUVORK5CYII="
DEMOCRATIC_ICON = "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"


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

    color = config.get("color", DEFAULT_COLOR)

    # Create unique cache key based on config values.
    # The only one that really matters for now is the number of participants
    includeBills = config.get("bills", True)
    latestBill = getBills(api_key)
    numberOfBills = len(latestBill["bills"])

    if config.get("randombill", True) == True:
        # Pick a random bill from the results
        print("Random bill: " + str(config.get("randombill", True)))
        randomBill = random.number(0, numberOfBills - 1)
    else:
        # Show latest bill
        randomBill = numberOfBills - 1

    bill = latestBill["bills"][randomBill]["latestAction"]["actionDate"] + ":\n" + \
        latestBill["bills"][randomBill]["title"] + " was " + \
        latestBill["bills"][randomBill]["latestAction"]["text"]

    billrender = render.Column(
        main_align="start",
        cross_align='start',
        children=[
            # render.Stack(
            # children=[

            render.Box(
                child=render.Text(
                    content="Congress",
                    color="#FF9944",
                ),
                height=8,
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

            render.Box(
                color=config.get("backcolor", DEFAULT_BACK_COLOR),
                child=render.Marquee(
                    height=32,
                    child=render.Column(
                        children=[
                            render.WrappedText(
                                content=bill,
                                color=color,
                                width=64,
                                align="left",
                            ),
                        ],
                        # expanded=True
                    ),
                    offset_start=16,
                    offset_end=16,
                    scroll_direction="vertical",
                )
            ),

        ],
    )

    # print("Bills: " + str(len(latestBill["bills"])) +
    #      " - First one: " + str(latestBill["bills"][randomBill]))

    includeMembers = config.get("members", False)
    latestMembers = getMembers(api_key)
    numberOfMembers = len(latestMembers["members"])
    randomMember = random.number(0, numberOfMembers - 1)

  # latestMembers["members"][randomMember]["name"] + "\n" + \
    member = latestMembers["members"][randomMember]["state"]
#        latestMembers["members"][randomMember]["party"] + " party"

    memberrender = render.Column(
        children=[
            render.Row(
                expanded=True,
                children=[
                    render.Image(
                        src=base64.decode(DEMOCRATIC_ICON),
                        width=24,
                        # height=10
                    ),
                    render.Marquee(
                        width=40,
                        scroll_direction="horizontal",
                        child=render.WrappedText(
                            content=latestMembers["members"][randomMember]["name"],
                            color=color,
                            width=40,
                            height=24
                        ),
                    )
                ]
            ),
            render.Row(
                main_align="end",
                expanded=True,
                children=[
                    render.Text(
                        content=member,
                        color=color,


                    ),
                ]
            )
        ]
    )

    # print("Members: " + str(len(latestMembers["members"])) +
    #      " - First one: " + str(latestMembers["members"][randomMember]))

    # Later, add QR Code options. Needs Tinyurl API integration
    # code = qrcode.generate(
    #    url="https://tinyurl.com/5n6t8b29",
    #    size="large",
    #    color="#fff",
    #    background="#000",
    # )

    # TO-DO
    # Perform some content jui-jitsu to clean up government references
    # remove (text: ...)
    # change <p> into new lines
    # lowercase first character of latestAction.text
    # Change date to text (using widget I think)

    # Decide what to show
    print("Include bills: " + str(includeBills) +
          " - Members: " + str(includeMembers))

    include = "bill"
    if includeMembers == True and includeBills == True:
        include = "bill" if random.number(0, 1) == 0 else "member"
    else:
        if includeMembers:
            include = "member"

    print("Including " + include)
    if include == "bill":
        content = billrender
    else:
        content = memberrender

    return render.Root(
        content,
        show_full_animation=bool(config.get("scroll", True)),
        delay=int(config.get("speed", 100)),
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
            display="Dark red",
            value="#990000",
        ),
        schema.Option(
            display="Green",
            value="#00FF00",
        ),
        schema.Option(
            display="Dark green",
            value="#009900",
        ),
        schema.Option(
            display="Purple",
            value="#FF00FF",
        ),
        schema.Option(
            display="Dark purple",
            value="#880088",
        ),
        schema.Option(
            display="Cyan",
            value="#00FFFF",
        ),
        schema.Option(
            display="White",
            value="#FFFFFF",
        ),
        schema.Option(
            display="Brown",
            value="#751811",
        ),
        schema.Option(
            display="Black",
            value="#000000",
        ),

    ]

    speed_options = [
        schema.Option(
            display="Slow Scroll",
            value="150",
        ),
        schema.Option(
            display="Medium Scroll",
            value="90",
        ),
        schema.Option(
            display="Fast Scroll",
            value="55",
        ),
    ]

    return schema.Schema(
        version="1",
        fields=[
            schema.Toggle(
                id="scroll",
                name="Scroll until the end",
                desc="Keep scrolling text even if it's longer than app-rotation time",
                icon="arrows-up-down",
                default=True,
            ),
            schema.Dropdown(
                id="speed",
                name="Scroll Speed",
                desc="Scrolling speed",
                icon="gauge",
                default=speed_options[1].value,
                options=speed_options,
            ),
            schema.Toggle(
                id="bills",
                name="Include bills",
                desc="Shows actions taken on bills in congress",
                icon="scroll",
                default=True,
            ),
            schema.Toggle(
                id="randombill",
                name="Randomize Bills",
                desc="Show Random bills",
                icon="shuffle",
                default=True,
            ),
            schema.Toggle(
                id="executive_orders",
                name="Executive Orders",
                desc="Show executive orders",
                icon="bullhorn",
                default=True,
            ),
            schema.Toggle(
                id="members",
                name="Include members",
                desc="Show a random member of congress",
                icon="people-group",
                default=False,
            ),
            schema.Dropdown(
                id="color",
                name="Text Color",
                desc="The color of text to be displayed.",
                icon="palette",
                default=color_options[0].value,
                options=color_options,
            ),
            schema.Dropdown(
                id="backcolor",
                name="Background Color",
                desc="The color of background to be displayed.",
                icon="palette",
                default=color_options[0].value,
                options=color_options,
            ),
        ],
    )
