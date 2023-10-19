load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("time.star", "time")


def fetch_recent_bills():
    now = time.now()
    last_month = now - time.parse_duration("3600h")  # Subtract 30 days
    last_month_str = last_month.format("%Y-%m")

    url = "https://www.congress.gov/api/v1/bills/search?search='{0}'&sort=-date&pageSize=20&api_key=DEMO_KEY".format(
        last_month_str)
    response = http.get(url)

    if response.status_code == 200:
        data = json.loads(response.text)
        print("data: " + data)
        bills = data["results"][0]["bills"]
        return bills
    else:
        return None


def select_random_bill(bills):
    if not bills:
        return None

    selected_bill = bills[time.random_int(0, len(bills) - 1)]
    return selected_bill


def render_root():
    print("start")
    bills = fetch_recent_bills()
    print("continue")
    selected_bill = select_random_bill(bills)
    print("allright then")

    if selected_bill:
        print("yes yes")
        bill_title = selected_bill["title"]
        bill_number = selected_bill["number"]
        message = "Bill: {0} - {1}".format(bill_number, bill_title)
    else:
        print("no no")
        message = "No recent bills found"

    img = render.Text(message)
    return [img]


def main(args):
    while True:
        root = render.Root(child=render_root())
        img = root.render()
        time.sleep(600)  # Update every 10 minutes
        return img
