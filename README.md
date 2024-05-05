#  Workout Exporter

**The iOS app to export workout data.**

You can export workout data as a JSON file easily so that you can analyze data. Only pool swim activity is supported at the moment.

## Usage

* Select period.
* Tap "Export Workout" button.
* A workouts.zip file will be created, and it can be shared e.g. by AirDrop. 
* A workouts.json file will be extracted from the workout.zip

## JSON File structure
* The workouts.json is the dictionary that includes 5 lists. 
  * workouts["workoutSummary"]: List of Workout activities.
  * workouts["workoutEventSegment"]: List of Event Segments. A workout can include one or more segments.
  * workouts["workoutEventLap"]: List of Event Lap. A segment can include one or more laps.
  * workouts["distanceSwimming"]: List of distance swimming per lap.
  * workouts["swimmingStrokeCount"]: List of swimming stroke counts per lap.
  * workouts["heartRate"]: List of heart rates. The timestamp of the data doesn't limit only to the activity period.
