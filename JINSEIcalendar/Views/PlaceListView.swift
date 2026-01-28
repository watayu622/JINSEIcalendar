import SwiftUI
import SwiftData
import MapKit

struct PlaceListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlaceToVisit.createdAt, order: .reverse) private var places: [PlaceToVisit]
    @State private var showingAddSheet = false
    @State private var filterVisited = false

    private var filteredPlaces: [PlaceToVisit] {
        if filterVisited {
            return places
        }
        return places.filter { !$0.isVisited }
    }

    var body: some View {
        NavigationStack {
            Group {
                if places.isEmpty {
                    ContentUnavailableView(
                        "行きたい場所を追加しよう",
                        systemImage: "mappin.and.ellipse",
                        description: Text("人生で訪れたい場所を登録して\n旅の計画を立てましょう")
                    )
                } else {
                    List {
                        ForEach(filteredPlaces) { place in
                            PlaceRow(place: place)
                        }
                        .onDelete(perform: deletePlaces)
                    }
                }
            }
            .navigationTitle("行きたい場所リスト")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        filterVisited.toggle()
                    } label: {
                        Image(systemName: filterVisited ? "eye" : "eye.slash")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddPlaceView()
            }
        }
    }

    private func deletePlaces(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredPlaces[index])
        }
    }
}

struct PlaceRow: View {
    @Bindable var place: PlaceToVisit
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    withAnimation {
                        place.isVisited.toggle()
                    }
                } label: {
                    Image(systemName: place.isVisited ? "mappin.circle.fill" : "mappin.circle")
                        .foregroundStyle(place.isVisited ? .green : .orange)
                        .font(.title3)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .font(.body)
                        .strikethrough(place.isVisited)
                        .foregroundStyle(place.isVisited ? .secondary : .primary)

                    if !place.address.isEmpty {
                        Text(place.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if !place.detail.isEmpty {
                        Text(place.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if let targetDate = place.targetDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(targetDate, style: .date)
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Google Maps ボタン
                Button {
                    openInGoogleMaps()
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "map.fill")
                            .font(.title3)
                        Text("地図")
                            .font(.caption2)
                    }
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }

            // ミニマップ表示（座標がある場合）
            if place.latitude != 0, place.longitude != 0 {
                MiniMapView(
                    latitude: place.latitude,
                    longitude: place.longitude,
                    name: place.name
                )
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 4)
    }

    private func openInGoogleMaps() {
        // Google Mapsアプリがあればアプリで開く、なければブラウザで開く
        if let appURL = place.googleMapsAppURL,
           UIApplication.shared.canOpenURL(appURL) {
            openURL(appURL)
        } else if let webURL = place.googleMapsURL {
            openURL(webURL)
        }
    }
}

struct MiniMapView: View {
    let latitude: Double
    let longitude: Double
    let name: String

    var body: some View {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        Map(initialPosition: .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))) {
            Marker(name, coordinate: coordinate)
                .tint(.orange)
        }
        .mapStyle(.standard)
        .disabled(true)
    }
}

struct AddPlaceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var detail = ""
    @State private var address = ""
    @State private var hasTargetDate = false
    @State private var targetDate = Date()
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            Form {
                Section("場所の情報") {
                    TextField("場所の名前", text: $name)
                        .onChange(of: name) { _, newValue in
                            if newValue.count >= 2 {
                                searchLocation(query: newValue)
                            }
                        }
                    TextField("メモ", text: $detail, axis: .vertical)
                        .lineLimit(2...4)
                }

                if !searchResults.isEmpty {
                    Section("検索結果（タップで選択）") {
                        ForEach(searchResults, id: \.self) { item in
                            Button {
                                selectPlace(item)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(item.name ?? "不明")
                                        .foregroundStyle(.primary)
                                    if let address = item.placemark.title {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                if !address.isEmpty {
                    Section("選択された場所") {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let coord = selectedCoordinate {
                            MiniMapView(
                                latitude: coord.latitude,
                                longitude: coord.longitude,
                                name: name
                            )
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        }
                    }
                }

                Section("目標日") {
                    Toggle("目標日を設定", isOn: $hasTargetDate)
                    if hasTargetDate {
                        DatePicker("目標日", selection: $targetDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("新しい場所")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        let place = PlaceToVisit(
                            name: name,
                            detail: detail,
                            latitude: selectedCoordinate?.latitude ?? 0,
                            longitude: selectedCoordinate?.longitude ?? 0,
                            address: address,
                            targetDate: hasTargetDate ? targetDate : nil
                        )
                        modelContext.insert(place)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func searchLocation(query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            searchResults = response?.mapItems ?? []
        }
    }

    private func selectPlace(_ item: MKMapItem) {
        name = item.name ?? name
        address = item.placemark.title ?? ""
        selectedCoordinate = item.placemark.coordinate
        searchResults = []
    }
}
