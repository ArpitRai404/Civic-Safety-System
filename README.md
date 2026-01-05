# Civic-Safety-System
An app developed using Google technologies to reduce/prevent the risks of crimes through community support

Problem Statement-
Crimes often escalate because help arrives too late. While authorities are essential, nearby people can play a critical role in delaying or preventing harm by acting as witnesses, calling for help, or helping the victim move to safer, crowded areas.

Solution-
This app enables users to quickly alert nearby community members and authorities during emergencies, allowing faster on-ground response before official help arrives.

How it works-
When in danger the user holds the button for 3 seconds, the app gives a countdown of 15 seconds(in case of accidental alarm). It then notifies the authorities and the users within 1.5 km of radius so that they can become witness, call for help, move in crowds to protect the victim etc.

Tech Stack(Google technologies)-
Flutter (Frontend – Google)
Firebase Cloud Messaging (FCM) – real-time notifications
FastAPI 
Firebase Admin SDK (used for sending FCM notifications from the backend)

Motivation-
In many real-world situations, every second matters.
Community members who are already nearby can delay, discourage, or prevent crimes, increasing the victim’s chances of safety until authorities arrive.

Project Status-
(Under development)

Pending tasks- 
Google API integration
Authentication (Firebase AUTH)
Database 
Authorities support 

Note-
The project is partially built and is still under development
While tested locally, the backend is designed to be deployed on Google Cloud Run.

