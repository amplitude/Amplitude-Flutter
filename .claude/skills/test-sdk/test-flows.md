# Test Flows

Reusable test scenarios for the Amplitude Flutter SDK example app. Each flow
defines the UI interactions to perform and the expected Amplitude events.

## Flow Format

Each flow is a structured block with:

- **id**: Short identifier used in SKILL.md
- **description**: What the flow tests
- **preconditions**: App state required before starting
- **steps**: Ordered list of UI actions
- **expected_events**: Amplitude event types that should appear after flush

## Locator Strategy

For mobile (user-mobile-mcp):
1. Call `mobile_list_elements_on_screen` to get element list
2. Find the target element by its text label
3. Use `mobile_click_on_screen_at_coordinates` with the element's coordinates
4. If the element is not visible, use `mobile_swipe_on_screen` to scroll down,
   then re-list elements

For web (cursor-ide-browser):
1. Call `browser_snapshot` to get element refs
2. Find the target element by its text content
3. Click using `browser_click` with the ref

## Scrolling

The example app is a long scrollable list. Elements near the bottom (Revenue,
Group, Opt Out/In, Flush Events) may require scrolling. The app layout top to
bottom:

1. Device ID form
2. User ID form
3. Reset button
4. Session ID display
5. Event form ("Send Event" button)
6. Identify form ("Send Identify" button)
7. Group form ("Set Group" button)
8. Group Identify form ("Send Group Identify" button)
9. Revenue form ("Send Revenue" button)
10. Opt Out / Opt In buttons
11. "Flush Events" button
12. Status message text

---

## basic-event

**Description**: Send the default "Dart Click" event and flush.

**Preconditions**: App is launched and initialized (status shows "Amplitude
initialized").

**Steps**:

| Step | Action                  | Target Element      | Expected Status Message |
|------|-------------------------|---------------------|-------------------------|
| 1    | Tap button              | "Send Event"        | "Event sent."           |
| 2    | Scroll down if needed   | --                  | --                      |
| 3    | Tap button              | "Flush Events"      | "Events flushed."       |

**Expected Events**:

```yaml
- event_type: "Dart Click"
  count: 1
```

**Notes**: The event name text field defaults to "Dart Click". No need to type
anything -- just tap "Send Event".

---

## identify

**Description**: Send an identify call with user properties and flush.

**Preconditions**: App is launched and initialized.

**Steps**:

| Step | Action                  | Target Element          | Expected Status Message |
|------|-------------------------|-------------------------|-------------------------|
| 1    | Scroll to Identify form | --                      | --                      |
| 2    | Tap button              | "Send Identify"         | "Identify sent."        |
| 3    | Scroll down if needed   | --                      | --                      |
| 4    | Tap button              | "Flush Events"          | "Events flushed."       |

**Expected Events**:

```yaml
- event_type: "$identify"
  count: 1
```

**Notes**: The identify form has optional key/value fields for custom user
properties. For the basic flow, skip filling them -- the form sends a default
`identify_test` property with a timestamp. If the test flow specifies custom
properties, type into "User Property Key" and "User Property Value" fields
before tapping "Send Identify".

---

## revenue

**Description**: Send a revenue event and flush.

**Preconditions**: App is launched and initialized.

**Steps**:

| Step | Action                  | Target Element          | Expected Status Message |
|------|-------------------------|-------------------------|-------------------------|
| 1    | Scroll to Revenue form  | --                      | --                      |
| 2    | Tap button              | "Send Revenue"          | "Revenue sent."         |
| 3    | Scroll down if needed   | --                      | --                      |
| 4    | Tap button              | "Flush Events"          | "Events flushed."       |

**Expected Events**:

```yaml
- event_type: "revenue_amount"
  count: 1
```

**Notes**: The revenue form has fields for product ID, quantity, and price.
The defaults are sufficient for a smoke test.

---

## set-group

**Description**: Set group membership and flush.

**Preconditions**: App is launched and initialized.

**Steps**:

| Step | Action                  | Target Element          | Expected Status Message |
|------|-------------------------|-------------------------|-------------------------|
| 1    | Scroll to Group form    | --                      | --                      |
| 2    | Tap button              | "Set Group"             | "Group set."            |
| 3    | Scroll down if needed   | --                      | --                      |
| 4    | Tap button              | "Flush Events"          | "Events flushed."       |

**Expected Events**:

```yaml
- event_type: "$identify"
  count: 1
```

**Notes**: Setting a group triggers an `$identify` event with group properties.
The group form has fields for group type and group name with defaults.

---

## full-smoke

**Description**: Run all flows sequentially on a single app session.

**Preconditions**: App is launched and initialized.

**Steps**: Execute the following flows in order, without restarting the app:

1. `basic-event`
2. `identify`
3. `revenue`
4. `set-group`
5. Final flush (tap "Flush Events" once more at the end)

**Expected Events** (combined):

```yaml
- event_type: "Dart Click"
  count: 1
- event_type: "$identify"
  count: 2
- event_type: "revenue_amount"
  count: 1
```

**Notes**: The `$identify` count is 2 because both the `identify` flow and the
`set-group` flow produce `$identify` events. The final flush ensures all
remaining events are sent. Some events may have been flushed in intermediate
steps already.
