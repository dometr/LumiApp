import Foundation
import CoreLocation

// Where the globe camera goes when a country is picked from the search bar.
// One line for every ISO alpha-2 country: "CODE latitude longitude zoom".
// Values are approximate (center of the country + a zoom that fits it on a phone):
// edit a single line to adjust one country. Big countries get a low zoom, micro states a high one.
enum CountryFocus {

    struct Target {
        let latitude: Double
        let longitude: Double
        let zoom: Double

        var center: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }

    // Used if a code is ever missing from the table: the globe stays centered, nothing breaks
    static let fallback = Target(latitude: 20, longitude: 0, zoom: 3.5)

    static func target(for isoCode: String) -> Target {
        table[isoCode.uppercased()] ?? fallback
    }

    private static let table: [String: Target] = {
        var result: [String: Target] = [:]
        for line in raw.split(separator: "\n") {
            let part = line.split(separator: " ")
            guard part.count == 4,
                  let lat = Double(part[1]),
                  let lon = Double(part[2]),
                  let zoom = Double(part[3]) else { continue }
            result[String(part[0])] = Target(latitude: lat, longitude: lon, zoom: zoom)
        }
        return result
    }()

    private static let raw = """
        AD 42.55 1.58 7.0
        AE 23.9 54.3 6.1
        AF 33.9 67.7 4.5
        AG 17.08 -61.8 7.0
        AI 18.22 -63.05 7.0
        AL 41.15 20.17 6.6
        AM 40.07 45.04 6.6
        AO -12.3 17.5 4.2
        AQ -80 0 1.8
        AR -37 -65 3.2
        AS -14.3 -170.7 7.0
        AT 47.6 14.1 5.6
        AU -25.7 134.5 2.8
        AW 12.52 -69.97 7.0
        AX 60.2 20 7.0
        AZ 40.3 47.6 5.8
        BA 44.17 17.8 6.1
        BB 13.19 -59.54 7.0
        BD 23.7 90.3 5.7
        BE 50.64 4.64 6.3
        BF 12.24 -1.56 5.3
        BG 42.73 25.5 5.6
        BH 26.05 50.55 7.0
        BI -3.37 29.9 7.0
        BJ 9.3 2.3 6.0
        BL 17.9 -62.83 7.0
        BM 32.3 -64.75 7.0
        BN 4.5 114.7 7.0
        BO -16.7 -64.7 4.3
        BQ 12.2 -68.3 7.0
        BR -10.8 -52.9 2.8
        BS 24.4 -76 5.8
        BT 27.4 90.4 6.6
        BV -54.42 3.36 7.0
        BW -22.3 24.7 4.7
        BY 53.7 27.95 4.8
        BZ 17.2 -88.7 7.0
        CA 60 -98 1.9
        CC -12.14 96.87 7.0
        CD -2.9 23.6 3.8
        CF 6.6 20.9 4.7
        CG -0.7 15.2 5.2
        CH 46.8 8.23 6.2
        CI 7.54 -5.55 5.2
        CK -21.24 -159.78 5.5
        CL -35.7 -71.5 3.4
        CM 5.7 12.7 4.9
        CN 35 103 2.3
        CO 4.1 -73 4.3
        CR 9.9 -84.1 6.5
        CU 21.6 -79 4.6
        CV 15.1 -23.6 6.0
        CW 12.17 -69 7.0
        CX -10.49 105.64 7.0
        CY 35 33.2 6.5
        CZ 49.8 15.5 5.6
        DE 51.1 10.4 4.8
        DJ 11.8 42.6 7.0
        DK 56 10 5.8
        DM 15.4 -61.35 7.0
        DO 18.9 -70.5 6.5
        DZ 28 2.6 3.6
        EC -1.4 -78.5 5.3
        EE 58.7 25.5 5.7
        EG 26.8 30 4.2
        EH 24.5 -13 5.2
        ER 15.4 39 5.9
        ES 40 -3.7 4.5
        ET 9 39.6 4.3
        FI 64.5 26 4.0
        FJ -17.8 178 6.0
        FK -51.8 -59.5 6.9
        FM 6.9 158.2 4.5
        FO 62 -6.9 7.0
        FR 46.6 2.4 4.8
        GA -0.8 11.6 5.4
        GB 54 -2.5 4.7
        GD 12.12 -61.68 7.0
        GE 42.2 43.5 5.9
        GF 4 -53 6.2
        GG 49.46 -2.58 7.0
        GH 7.95 -1 5.4
        GI 36.14 -5.35 7.0
        GL 72 -40 2.6
        GM 13.45 -15.4 6.4
        GN 10.9 -10.9 5.4
        GP 16.25 -61.55 7.0
        GQ 1.6 10.5 6.0
        GR 39 22 5.3
        GS -54.4 -36.7 7.0
        GT 15.7 -90.4 6.0
        GU 13.44 144.79 7.0
        GW 12 -15 6.8
        GY 4.8 -58.9 5.5
        HK 22.35 114.15 7.0
        HM -53.1 73.5 7.0
        HN 14.8 -86.6 5.9
        HR 45.1 15.2 5.6
        HT 19 -72.7 6.9
        HU 47.2 19.4 5.6
        ID -2.5 118 2.7
        IE 53.2 -8 5.6
        IL 31.4 35 6.2
        IM 54.23 -4.55 7.0
        IN 22.5 79.5 3.2
        IO -7.33 72.4 7.0
        IQ 33 43.7 4.8
        IR 32.4 53.7 3.8
        IS 64.9 -18.5 4.8
        IT 42.5 12.5 4.6
        JE 49.21 -2.13 7.0
        JM 18.15 -77.3 6.6
        JO 31 36.5 5.9
        JP 36.5 138 3.9
        KE 0.2 37.9 4.8
        KG 41.5 74.6 5.2
        KH 12.7 104.9 5.6
        KI 1.45 173 5.5
        KM -11.9 43.4 7.0
        KN 17.33 -62.75 7.0
        KP 40.3 127.2 5.5
        KR 36.4 127.9 5.8
        KW 29.3 47.6 7.0
        KY 19.3 -81.25 7.0
        KZ 48 67 3.1
        LA 18.5 103.7 5.4
        LB 33.9 35.85 6.8
        LC 13.9 -60.97 7.0
        LI 47.15 9.55 7.0
        LK 7.9 80.7 6.4
        LR 6.4 -9.4 6.0
        LS -29.6 28.3 6.7
        LT 55.2 23.9 5.6
        LU 49.8 6.1 7.0
        LV 56.9 24.9 5.5
        LY 27 17 3.8
        MA 31.9 -6.5 4.8
        MC 43.74 7.42 7.0
        MD 47.2 28.5 6.3
        ME 42.7 19.3 7.0
        MF 18.07 -63.05 7.0
        MG -19.4 46.7 4.7
        MH 7.1 171.2 5.2
        MK 41.6 21.7 6.6
        ML 17.5 -3.5 4.2
        MM 21 96.5 3.9
        MN 46.9 103.8 3.5
        MO 22.2 113.55 7.0
        MP 15.2 145.75 7.0
        MQ 14.64 -61 7.0
        MR 20.3 -10.4 4.3
        MS 16.74 -62.19 7.0
        MT 35.9 14.4 7.0
        MU -20.3 57.55 7.0
        MV 3.5 73.3 5.3
        MW -13.25 34.3 5.3
        MX 23.6 -102.5 3.3
        MY 4.2 108.5 4.6
        MZ -18.7 35.5 3.8
        NA -22.1 17.1 4.4
        NC -21.3 165.5 6.2
        NE 17.4 9.4 4.2
        NF -29.04 167.95 7.0
        NG 9.6 8.1 4.4
        NI 12.9 -85 5.8
        NL 52.2 5.3 6.0
        NO 64.5 12 3.5
        NP 28.2 84 5.6
        NR -0.53 166.93 7.0
        NU -19.05 -169.87 7.0
        NZ -41.5 173 3.9
        OM 21 56.5 5.2
        PA 8.5 -80.1 5.8
        PE -9.2 -75 4.2
        PF -17.6 -149.5 5.0
        PG -6.3 144 4.5
        PH 12.8 122 4.5
        PK 30 69.5 4.3
        PL 52 19.4 4.6
        PM 46.9 -56.3 7.0
        PN -24.37 -128.32 7.0
        PR 18.2 -66.5 7.0
        PS 31.95 35.2 7.0
        PT 39.6 -8 5.8
        PW 7.5 134.6 7.0
        PY -23.4 -58.4 4.9
        QA 25.35 51.2 7.0
        RE -21.1 55.5 7.0
        RO 45.9 24.97 4.9
        RS 44 20.8 5.7
        RU 61.5 90 2.0
        RW -1.95 29.9 7.0
        SA 24 45 3.7
        SB -9 160 4.8
        SC -4.65 55.5 6.0
        SD 15.6 30 3.9
        SE 62 15 3.9
        SG 1.35 103.82 7.0
        SH -15.95 -5.7 7.0
        SI 46.1 14.8 6.7
        SJ 78.5 17 4.0
        SK 48.7 19.7 6.0
        SL 8.5 -11.8 6.3
        SM 43.94 12.46 7.0
        SN 14.5 -14.5 5.5
        SO 5.2 46.2 4.0
        SR 4 -56 5.7
        SS 7.3 30 4.7
        ST 0.33 6.73 7.0
        SV 13.7 -88.9 7.0
        SX 18.04 -63.07 7.0
        SY 35 38.5 5.3
        SZ -26.5 31.5 7.0
        TC 21.8 -71.8 7.0
        TD 15.5 18.7 4.2
        TF -49.3 69.3 5.5
        TG 8.6 0.98 6.5
        TH 15.1 101 4.3
        TJ 38.9 71 5.5
        TK -9.2 -171.85 7.0
        TL -8.8 125.9 7.0
        TM 39 59.6 4.6
        TN 34 9.5 5.4
        TO -20 -174.9 5.2
        TR 39 35.2 3.9
        TT 10.5 -61.3 7.0
        TV -7.5 178.7 5.5
        TW 23.7 121 6.3
        TZ -6.3 34.9 4.4
        UA 48.4 31.2 4.2
        UG 1.3 32.3 5.4
        UM 19.3 166.6 7.0
        US 39.8 -98.6 2.3
        UY -32.8 -56 5.4
        UZ 41.4 64.6 4.6
        VA 41.9 12.45 7.0
        VC 13.25 -61.2 7.0
        VE 7.1 -66.2 4.5
        VG 18.43 -64.62 7.0
        VI 18.34 -64.9 7.0
        VN 16 107.8 4.2
        VU -16 167.2 4.6
        WF -13.77 -177.15 7.0
        WS -13.75 -172.1 7.0
        YE 15.6 47.6 4.8
        YT -12.8 45.15 7.0
        ZA -29 24.5 4.1
        ZM -13.5 27.8 4.6
        ZW -19 29.8 5.0
        """
}
