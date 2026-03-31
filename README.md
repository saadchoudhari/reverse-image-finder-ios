# Reverse Image Finder (iOS)

A SwiftUI-based iOS application that allows users to upload an image and perform reverse image searches using Google Lens, Yandex, and SerpAPI.

## Overview

Reverse Image Finder lets users:

- Select an image from their photo library
- Search the image using Google Lens
- Search the image using Yandex
- Find matching websites via SerpAPI
- Open results inside the app using SafariView

This project demonstrates practical API integration and async networking in Swift.

## Features

- Image selection using PhotosPicker
- Reverse image search using SerpAPI
- Google Lens integration
- Yandex image search integration
- In-app Safari browser (SFSafariViewController)
- Async/Await networking with URLSession
- Secure API key loading via Config.plist
- Error handling and loading states

## Tech Stack

- Swift
- SwiftUI
- UIKit (UIImage handling)
- PhotosUI
- URLSession
- SerpAPI

## How It Works

1. The user selects an image.
2. The image is uploaded to SerpAPI’s proxy endpoint.
3. A reverse image search is performed using the returned image URL.
4. Matching websites are displayed in a list.
5. Tapping a result opens it inside the app.

## Setup Instructions

### 1. Clone the repository

git clone https://github.com/yourusername/reverse-image-finder-ios.git

### 2. Open the project in Xcode

Open the .xcodeproj file in Xcode 15+.

### 3. Add your API key

Create a file named Config.plist and add:

Key: SerpAPIKey  
Type: String  
Value: YOUR_SERPAPI_KEY  

You can get a free API key from:
https://serpapi.com/


## Project Structure

- ContentView.swift – Main UI
- ImageSearchService.swift – Networking & API logic
- Models.swift – Data models
- SafariView.swift – In-app browser
- ReverseImageFinderApp.swift – App entry point

## Resume Description

Built an iOS reverse image search application using SwiftUI and SerpAPI. Implemented multipart image uploads, external API integration, async networking, and dynamic result rendering with in-app browser support.

## Author

Saad Choudhari  
Computer Science Student  
