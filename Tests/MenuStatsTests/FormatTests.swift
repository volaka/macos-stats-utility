import Testing
@testable import MenuStats

@Test func bytesUseDecimalUnits() {
    #expect(Format.bytes(512) == "512 B")
    #expect(Format.bytes(1_200) == "1.2 KB")
    #expect(Format.bytes(9_800_000_000) == "9.8 GB")
}

@Test func rateAppendsPerSecond() {
    #expect(Format.rate(1_200_000) == "1.2 MB/s")
}

@Test func percentRoundsToWholeNumber() {
    #expect(Format.percent(0.614) == "61%")
}

@Test func memoryUsesBinaryUnitsLikeActivityMonitor() {
    #expect(Format.memory(36 * 1024 * 1024 * 1024) == "36.0 GB")
}

@Test func bytesMoveToNextUnitWhenRoundingReachesIt() {
    #expect(Format.bytes(999_960) == "1.0 MB")
}
