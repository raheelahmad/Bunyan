//
//  SKLFetcherTests.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/1/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLCoreDataTests.h"
#import "SKLTestableAPIClient.h"
#import "SKLManagedObject.h"
#import "SKLTestableManagedObjectContext.h"
#import "SKLRemoteRequestInfo.h"
#import "SKLMockURLSession.h"

// Dependency injected objects
SKLTestableAPIClient *apiClient;
SKLTestableManagedObjectContext *context;
BOOL shouldMockUpdateWithRemoteResponse;

// Returned objects
id responseObject;
NSError *error;

// ----

@interface SKLFakePerson : SKLManagedObject
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *location;
@property (nonatomic) NSNumber *remoteId;
@end

@implementation SKLFakePerson

@dynamic name, location, remoteId;

+ (SKLRemoteRequestInfo *)remoteFetchInfo {
	SKLRemoteRequestInfo *info = [[SKLRemoteRequestInfo alloc] init];
	info.path = @"/get/persons";
	return info;
}

+ (SKLAPIClient *)apiClient {
	return apiClient;
}

+ (void)updateWithRemoteFetchResponse:(NSArray *)response {
	if (shouldMockUpdateWithRemoteResponse) {
		responseObject = response;
	} else {
		[super updateWithRemoteFetchResponse:response];
	}
}

+ (NSDictionary *)localToRemoteKeyMapping {
	return @{
			 @"remoteId" : @"id",
			 @"name" : @"name",
			 @"location" : @"location",
			 };
}

+ (NSManagedObjectContext *)importContext {
	return context;
}

+ (id)uniquingKey {
	return @"remoteId";
}

@end


// ----

@interface SKLFetcherTests : SKLCoreDataTests

@end

@implementation SKLFetcherTests

- (void)testFetchMakesCorrectEndpointAPIRequest {
	[SKLFakePerson fetch];
	NSURLRequest *requestMade = apiClient.mockSession.lastRequest;
	NSString *path = [[NSURLComponents componentsWithURL:requestMade.URL resolvingAgainstBaseURL:NO] path];
	XCTAssertEqualObjects(path, @"/get/persons", @"Fetch should be made with model request info path");
}

- (void)testFetchResponseUpdatesModel {
	shouldMockUpdateWithRemoteResponse = YES;
	[self makePersonFetchResponse];
	XCTAssertNotNil(responseObject, @"Fetch response should call the model");
}

- (void)testFetchResponseCreatesLocalObjects {
	[self makePersonFetchResponse];
	
	NSArray *people = [SKLFakePerson allInContext:self.context];
	XCTAssertEqual([people count], (NSUInteger)2, @"Should insert objects after fetch");
}

- (void)testFetchResponseCreatesLocalObjectsWithRemoteValues {
	[self makePersonFetchResponse];
	
	[self checkForPersonWithId:@126 hasName:@"Plato" location:@"Greece"];
	[self checkForPersonWithId:@120 hasName:@"Al Farabi" location:@"Persia"];
}

- (void)testFetchResponseUpdatesExistingLocalObject {
	SKLFakePerson *platoEarlier = [SKLFakePerson insertInContext:self.context];
	platoEarlier.name = @"Plllaatoooo";
	platoEarlier.location = @"Crimea";
	platoEarlier.remoteId = @126; // remoteId will match the remote Plato object
	
	[self makePersonFetchResponse];
	
	NSPredicate *platoPredicate = [NSPredicate predicateWithFormat:@"remoteId == %@", @126];
	NSArray *allPlatos = [SKLFakePerson allInContext:self.context predicate:platoPredicate];
	XCTAssertEqual([allPlatos count], (NSUInteger)1, @"Update should match the existing object");
	SKLFakePerson *platoLater = [allPlatos firstObject];
	XCTAssertEqualObjects(platoLater, platoEarlier, @"Update should match the existing object");
	
	XCTAssertEqualObjects(platoEarlier.name, @"Plato", @"Update should match the existing object");
}

- (void)checkForPersonWithId:(NSNumber *)remoteId hasName:(NSString *)name location:(NSString *)location {
	NSPredicate *singlePersonPredicate = [NSPredicate predicateWithFormat:@"remoteId == %@", remoteId];
	SKLFakePerson *plato = [[SKLFakePerson allInContext:self.context predicate:singlePersonPredicate] firstObject];
	XCTAssertEqualObjects(plato.name, name, @"Remote fetch response should create local object with remote values");
	XCTAssertEqualObjects(plato.location, location, @"Remote fetch response should create local object with remote values");
}

- (void)makePersonFetchResponse {
	self.context.shouldSaveAsyncAsSync = YES;
	[SKLFakePerson fetch];
	
    NSDictionary *jsonResponseHeaderDict = @{ @"Content-Type" : @"application/json" };
	NSArray *personFetchResponse = @[
									 @{ @"id" : @126, @"name" : @"Plato", @"location" : @"Greece" },
									 @{ @"id" : @120, @"name" : @"Al Farabi", @"location" : @"Persia" },
									 ];
	NSData *responseData = [NSJSONSerialization dataWithJSONObject:personFetchResponse options:0 error:nil];
	NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]
															  statusCode:200
															 HTTPVersion:@"1.1"
															headerFields:jsonResponseHeaderDict];
	apiClient.mockSession.lastCompletionHandler(responseData, response, nil);
}

- (NSManagedObjectModel *)loadCustomModel {
	NSEntityDescription *personEntity = [self entityWithName:NSStringFromClass([SKLFakePerson class])
									   attributes:@[
													@{ SKLAttrNameKey : @"name", SKLAttrTypeKey : @"string" },
													@{ SKLAttrNameKey : @"location", SKLAttrTypeKey : @"string" },
													@{ SKLAttrNameKey : @"remoteId", SKLAttrTypeKey : @"int" }
													]
									];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] init];
    model.entities = @[ personEntity ];
    return model;
}


- (void)setUp {
    [super setUp];
	
	shouldMockUpdateWithRemoteResponse = NO;
	context = self.context;
	apiClient = [[SKLTestableAPIClient alloc] initWithBaseURL:@"http://sakunlabs.com"];
	apiClient.mockSession = [[SKLMockURLSession alloc] init];
}

- (void)tearDown {
	apiClient = nil;
	responseObject = nil;
	error = nil;
	
    [super tearDown];
}

@end
