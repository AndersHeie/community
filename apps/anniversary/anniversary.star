"""
Applet: Anniversary
Summary: Anniversary reminders
Description: Setup an anniversary time and date, and get reminded at specific times before the anniversary.
Author: Anders Heie
"""


load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

FALLBACK_ANNIVERSARY = "My first burrito"
DEFAULT_LOCATION = """
{
	"lat": "32.970334205848",
	"lng": "-117.03731100460709",
	"description": "Old Poway Park, Poway, CA",
	"locality": "Poway",
	"place_id": "ChIJKwVFzl7624ARr_fRGpFkoS0",
	"timezone": "America/Los_Angeles"
}
"""

def main(config):
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]

    now = time.now().in_location(timezone)
    today_in_words = now.format("Monday").lower()

    default_reminder = config.get("anniversary", FALLBACK_ANNIVERSARY)
    todays_reminder = config.get(today_in_words, default_reminder)

    reminder = todays_reminder or default_reminder or FALLBACK_ANNIVERSARY

    return render.Root(
        render.Column(
            children = [
                render.Box(
                    color = "#FFF",
                    height = 9,
                    child = render.Row(
                        children = [
                            render.Text(
                                "{}".format(today_in_words),
                                color = "#000",
                            ),
                        ],
                    ),
                ),
                render.Box(
                    child = render.Row(
                        children = [
                            render.Marquee(
                                width = 64,
                                child = render.Text(
                                    content = reminder,
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

description = "Remind me to..."
calendar_icon = "calendar"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for timezone",
                icon = "locationDot",
            ),
            schema.Text(
                id = "anniversary",
                name = "Anniversary",
                desc = "What's the occasion?",
                icon = calendar_icon,
            )
        ],
    )
