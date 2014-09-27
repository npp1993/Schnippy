//
//  ViewController.m
//  SavingImagesTutorial
//
//  Created by Sidwyn Koh on 29/1/12.
//  Copyright (c) 2012 Parse. All rights reserved.
//
//  Photo credits: Stock Exchange (http://www.sxc.hu/)

#import "ViewController.h"
#import "PhotoDetailViewController.h"

@implementation ViewController

#define PADDING_TOP 0 // For placing the images nicely in the grid
#define PADDING 4
#define THUMBNAIL_COLS 1
#define THUMBNAIL_WIDTH 200
#define THUMBNAIL_HEIGHT 75

@synthesize navigationBar;

NSString *photoCaptionText;
NSData *currentImageData;
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidLoad
{
    photoCaptionText = @"is this working...";
    [super viewDidLoad];
    allImages = [[NSMutableArray alloc] init];
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationBar.shadowImage = [UIImage new];
    self.navigationBar.translucent = YES;
    [self refresh:NULL];
}
#pragma mark - Main methods

- (IBAction)refresh:(id)sender
{
    

    
    
    NSLog(@"Showing Refresh HUD");
    refreshHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:refreshHUD];
	
    // Register for HUD callbacks so we can remove it from the window at the right time
    refreshHUD.delegate = self;
	
    // Show the HUD while the provided method executes in a new thread
    [refreshHUD show:YES];
    
    PFQuery *query = [PFQuery queryWithClassName:@"UserPhoto"];
    PFUser *user = [PFUser currentUser];
    [query orderByDescending:@"rating"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // The find succeeded.
            if (refreshHUD) {
                [refreshHUD hide:YES];
                
                refreshHUD = [[MBProgressHUD alloc] initWithView:self.view];
                [self.view addSubview:refreshHUD];
                
                // The sample image is based on the work by http://www.pixelpressicons.com, http://creativecommons.org/licenses/by/2.5/ca/
                // Make the customViews 37 by 37 pixels for best results (those are the bounds of the build-in progress indicators)
                refreshHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
                
                // Set custom view mode
                refreshHUD.mode = MBProgressHUDModeCustomView;
                
                refreshHUD.delegate = self;
            }
            NSLog(@"Successfully retrieved %d photos.", objects.count);
            
            // Retrieve existing objectIDs
            allImages = [NSMutableArray new];
            NSMutableArray *oldCompareObjectIDArray = [NSMutableArray array];
            for (UIView *view in [photoScrollView subviews]) {
                if ([view isKindOfClass:[UIButton class]]) {
                    UIButton *eachButton = (UIButton *)view;
                    //[oldCompareObjectIDArray addObject:[eachButton titleForState:UIControlStateReserved]];
                }
            }
                        
            NSMutableArray *oldCompareObjectIDArray2 = [NSMutableArray arrayWithArray:oldCompareObjectIDArray];
            
            
            // If there are photos, we start extracting the data
            // Save a list of object IDs while extracting this data
            
            NSMutableArray *newObjectIDArray = [NSMutableArray array];            
            if (objects.count > 0) {
                for (PFObject *eachObject in objects) {
                    [newObjectIDArray addObject:[eachObject objectId]];
                }
            }
            
            // Compare the old and new object IDs
            NSMutableArray *newCompareObjectIDArray = [NSMutableArray arrayWithArray:newObjectIDArray];
            NSMutableArray *newCompareObjectIDArray2 = [NSMutableArray arrayWithArray:newObjectIDArray];
            if (oldCompareObjectIDArray.count > 0) {
                // New objects
                [newCompareObjectIDArray removeObjectsInArray:oldCompareObjectIDArray];
                // Remove old objects if you delete them using the web browser
                [oldCompareObjectIDArray removeObjectsInArray:newCompareObjectIDArray2];
                if (oldCompareObjectIDArray.count > 0) {
                    // Check the position in the objectIDArray and remove
                    NSMutableArray *listOfToRemove = [[NSMutableArray alloc] init];
                    for (NSString *objectID in oldCompareObjectIDArray){
                        int i = 0;
                        for (NSString *oldObjectID in oldCompareObjectIDArray2){
                            if ([objectID isEqualToString:oldObjectID]) {
                                // Make list of all that you want to remove and remove at the end
                                [listOfToRemove addObject:[NSNumber numberWithInt:i]];
                            }
                            i++;
                        }
                    }
                    
                    // Remove from the back
                    NSSortDescriptor *highestToLowest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
                    [listOfToRemove sortUsingDescriptors:[NSArray arrayWithObject:highestToLowest]];
                    
                    for (NSNumber *index in listOfToRemove){                        
                        [allImages removeObjectAtIndex:[index intValue]];
                    }
                    
                    
                    
                }
            }
            
            // Add new objects
            for (NSString *objectID in newCompareObjectIDArray){
                for (PFObject *eachObject in objects){
                    if ([[eachObject objectId] isEqualToString:objectID]) {
                        NSMutableArray *selectedPhotoArray = [[NSMutableArray alloc] init];
                        [selectedPhotoArray addObject:eachObject];
                                                
                        if (selectedPhotoArray.count > 0) {
                            [allImages addObjectsFromArray:selectedPhotoArray];                
                        }
                    }
                }
            }
            
            // Remove and add from objects before this
            [self setUpImages:allImages];
            
        } else {
            [refreshHUD hide:YES];
            
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

- (IBAction)cameraButtonTapped:(id)sender
{
    // Check for camera
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES) {
        // Create image picker controller
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        
        // Set source to the camera
        imagePicker.sourceType =  UIImagePickerControllerSourceTypeCamera;
        
        // Delegate is self
        imagePicker.delegate = self;
        
        // Show image picker
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
 
}

- (void)uploadImage:(NSData *)imageData withCaption: (NSString *) caption
{
    PFFile *imageFile = [PFFile fileWithName:@"Image.jpg" data:imageData];
    
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Uploading";
    [HUD show:YES];
    
    // Save PFFile
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            //Hide determinate HUD
            [HUD hide:YES];
            
            // Show checkmark
            HUD = [[MBProgressHUD alloc] initWithView:self.view];
            [self.view addSubview:HUD];
            
            // The sample image is based on the work by http://www.pixelpressicons.com, http://creativecommons.org/licenses/by/2.5/ca/
            // Make the customViews 37 by 37 pixels for best results (those are the bounds of the build-in progress indicators)
            HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
            
            // Set custom view mode
            HUD.mode = MBProgressHUDModeCustomView;
            
            HUD.delegate = self;

            // Create a PFObject around a PFFile and associate it with the current user
            PFObject *userPhoto = [PFObject objectWithClassName:@"UserPhoto"];
            [userPhoto setObject:imageFile forKey:@"imageFile"];
            [userPhoto setObject:caption forKey:@"Caption"];
            
            // Set the access control list to current user for security purposes
            //userPhoto.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
            
            PFUser *user = [PFUser currentUser];
            [userPhoto setObject:user forKey:@"user"];
            
            [userPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    [self refresh:nil];
                }
                else{
                    // Log details of the failure
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                }
            }];
        }
        else{
            [HUD hide:YES];
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    } progressBlock:^(int percentDone) {
        // Update your progress spinner here. percentDone will be between 0 and 100.
        HUD.progress = (float)percentDone/100;
    }];
}

- (void)setUpImages:(NSArray *)images
{
    // Contains a list of all the BUTTONS
    allImages = [images mutableCopy];
    
    // This method sets up the downloaded images and places them nicely in a grid
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSMutableArray *imageDataArray = [NSMutableArray array];
        
        // Iterate over all images and get the data from the PFFile
        for (int i = 0; i < images.count; i++) {
            PFObject *eachObject = [images objectAtIndex:i];
            PFFile *theImage = [eachObject objectForKey:@"imageFile"];
            NSData *imageData = [theImage getData];
            UIImage *image = [UIImage imageWithData:imageData];
            [imageDataArray addObject:image];
        }
                   
        // Dispatch to main thread to update the UI
        dispatch_async(dispatch_get_main_queue(), ^{
            // Remove old grid
            for (UIView *view in [photoScrollView subviews]) {
                if ([view isKindOfClass:[UIButton class]]) {
                    [view removeFromSuperview];
                }
            }
            
            
            // Create the buttons necessary for each image in the grid
            double aspectRatio = .65;
            for (int i = 0; i < [imageDataArray count]; i++) {
                PFObject *eachObject = [images objectAtIndex:i];
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                UIImage *image = [imageDataArray objectAtIndex:i];
                [button setImage:image forState:UIControlStateNormal];
                button.showsTouchWhenHighlighted = YES;
                button.tag = -1;
                button.frame = CGRectMake(0,
                                          [UIScreen mainScreen].bounds.size.height*i*aspectRatio,
                                          [UIScreen mainScreen].bounds.size.width,
                                          [UIScreen mainScreen].bounds.size.height*aspectRatio);
                button.imageView.contentMode = UIViewContentModeScaleAspectFill;
                [button setTitle:[eachObject objectId] forState:UIControlStateReserved];
                [photoScrollView addSubview:button];
                
                double padding = [UIScreen mainScreen].bounds.size.height*aspectRatio*.24;
                UILabel *countLabel = [UILabel new];
                
                //countLabel.text = (NSString*)[eachObject valueForKey:@"rating"];
                //NSLog(@"%@",[[eachObject valueForKey:@"rating"] class]);
                NSDecimalNumber *ratingValue = [eachObject valueForKey:@"rating"];
                countLabel.tag = i;
                countLabel.text = [ratingValue stringValue];
                countLabel.textAlignment = UITextAlignmentCenter;
                countLabel.textColor = [UIColor whiteColor];
                countLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
                countLabel.frame = CGRectMake([UIScreen mainScreen].bounds.size.width*.83,
                                              [UIScreen mainScreen].bounds.size.height*i*aspectRatio+padding,
                                              [UIScreen mainScreen].bounds.size.width*.14,
                                              [UIScreen mainScreen].bounds.size.height*aspectRatio*.425);
                [photoScrollView addSubview:countLabel];
                
                padding = [UIScreen mainScreen].bounds.size.height*aspectRatio*.80;
                UILabel *captionLabel = [UILabel new];
                NSString *newCaption = [eachObject valueForKey:@"Caption"];
                captionLabel.tag = -2;
                captionLabel.numberOfLines = 0;
                captionLabel.lineBreakMode = NSLineBreakByWordWrapping;
                captionLabel.text = newCaption;
                captionLabel.textAlignment = UITextAlignmentCenter;
                captionLabel.textColor = [UIColor whiteColor];
                captionLabel.frame = CGRectMake([UIScreen mainScreen].bounds.size.width*0,
                                              [UIScreen mainScreen].bounds.size.height*i*aspectRatio+padding,
                                              [UIScreen mainScreen].bounds.size.width,
                                              [UIScreen mainScreen].bounds.size.height*aspectRatio*.2);
                [photoScrollView addSubview:captionLabel];

                
                padding = [UIScreen mainScreen].bounds.size.height*aspectRatio*.3;
                UIButton *upButton= [UIButton buttonWithType:UIButtonTypeCustom];
                [upButton setImage:[UIImage imageNamed:@"plus-50.png"] forState:UIControlStateNormal];
                upButton.showsTouchWhenHighlighted = YES;
                upButton.tag = i;
                upButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width*.85,
                                          [UIScreen mainScreen].bounds.size.height*i*aspectRatio+padding,
                                          [UIScreen mainScreen].bounds.size.width*.1,
                                          [UIScreen mainScreen].bounds.size.height*aspectRatio*.1);
                upButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
                upButton.titleLabel.shadowColor = [UIColor greenColor];
                upButton.layer.shadowColor = [[UIColor greenColor]CGColor];
                upButton.layer.shadowOpacity = 1;
                upButton.layer.shadowRadius = 12;
                [upButton setTitle:[eachObject objectId] forState:UIControlStateReserved];
                [upButton addTarget:self action:@selector(upButtonTouched:) forControlEvents:UIControlEventTouchUpInside];

                
                
                padding = [UIScreen mainScreen].bounds.size.height*aspectRatio*.5;
                UIButton *downButton= [UIButton buttonWithType:UIButtonTypeCustom];
                downButton.layer.shadowColor = [[UIColor redColor]CGColor];
                downButton.layer.shadowOpacity = 1;
                downButton.layer.shadowRadius = 12;
                [downButton setImage:[UIImage imageNamed:@"minus-50.png"] forState:UIControlStateNormal];
                downButton.showsTouchWhenHighlighted = YES;
                downButton.tag = i;
                downButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width*.85,
                                            [UIScreen mainScreen].bounds.size.height*i*aspectRatio+padding,
                                            [UIScreen mainScreen].bounds.size.width*.1,
                                            [UIScreen mainScreen].bounds.size.height*aspectRatio*.1);
                downButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
                
                [downButton setTitle:[eachObject objectId] forState:UIControlStateReserved];
                [downButton addTarget:self action:@selector(downButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
                
                
                //Lets see if the current user has already upvoted the photo
                NSArray *upVotes = [eachObject valueForKey:@"UserUpvoted"];
                for (NSString  *user in upVotes) {
                    //NSLog(@"%@",user);
                    //NSLog(@"%@",[PFUser currentUser].username);
                    if (![user compare:[PFUser currentUser].username]) {
                        [upButton setEnabled:0];
                        [downButton setEnabled:0];
                        upButton.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.2];
                    }
                }
                
                NSArray *downVotes = [eachObject valueForKey:@"UserDownvoted"];
                for (NSString  *user in downVotes) {
                    //NSLog(@"%@",user);
                    //NSLog(@"%@",[PFUser currentUser].username);
                    if (![user compare:[PFUser currentUser].username]) {
                        [upButton setEnabled:0];
                        [downButton setEnabled:0];
                        downButton.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.2];
                    }
                }
                
                [photoScrollView addSubview:upButton];
                [photoScrollView addSubview:downButton];


            }
            
            // Size the grid accordingly
            int height = [UIScreen mainScreen].bounds.size.height*aspectRatio * [imageDataArray count];
            
            photoScrollView.contentSize = CGSizeMake(self.view.frame.size.width, height);
            photoScrollView.clipsToBounds = YES;
            
        });
    });
}

- (void)upButtonTouched:(id)sender {
    // When picture is touched, open a viewcontroller with the image
    PFObject *theObject = (PFObject *)[allImages objectAtIndex:[sender tag]];

    for (UIView *view in [photoScrollView subviews]) {
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)view;
            if (label.tag == [sender tag]) {
                NSDecimalNumber *rating = [theObject valueForKey:@"rating"];
                NSDecimalNumber *numOne   = [NSDecimalNumber numberWithFloat:1.0];
                rating = [rating decimalNumberByAdding:numOne];
                label.text = [rating stringValue];
            }
        }
    }
                                   
                                   
    [theObject incrementKey:@"rating"];
    [theObject saveInBackground];
    
    UIButton *senderButton = sender;
    senderButton.enabled = 0;
    senderButton.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.2];
    
    for (UIView *view in [photoScrollView subviews]) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)view;
            if (button.tag == [sender tag]) {
                button.enabled = false;
            }
        }
    }
    
    [theObject addUniqueObject:[PFUser currentUser].username forKey:@"UserUpvoted"];
    [theObject saveInBackground];
}

- (void)downButtonTouched:(id)sender {
    // When picture is touched, open a viewcontroller with the image
    PFObject *theObject = (PFObject *)[allImages objectAtIndex:[sender tag]];

    for (UIView *view in [photoScrollView subviews]) {
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)view;
            if (label.tag == [sender tag]) {
                NSDecimalNumber *rating = [theObject valueForKey:@"rating"];
                NSDecimalNumber *numOne   = [NSDecimalNumber numberWithFloat:-1.0];
                rating = [rating decimalNumberByAdding:numOne];
                label.text = [rating stringValue];
            }
        }
    }
    
    [theObject incrementKey:@"rating" byAmount:[NSNumber numberWithInt:-1]];
    [theObject saveInBackground];
    
    UIButton *senderButton = sender;
    senderButton.enabled = 0;
    senderButton.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.2];
    
    for (UIView *view in [photoScrollView subviews]) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)view;
            if (button.tag == [sender tag]) {
                button.enabled = false;
            }
        }
    }
    
    [theObject addUniqueObject:[PFUser currentUser].username forKey:@"UserDownvoted"];
    [theObject saveInBackground];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSLog(@"Button Index =%ld",buttonIndex);
    if (buttonIndex == 1) {  //Add
        UITextField *caption = [alertView textFieldAtIndex:0];
        NSLog(@"Caption: %@", caption.text);
        photoCaptionText = caption.text;
        [self uploadImage:currentImageData withCaption:photoCaptionText];
    }else{
        photoCaptionText = @"";
        [self uploadImage:currentImageData withCaption:photoCaptionText];
    }
}

#pragma mark - View lifecycle

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Access the uncropped image from info dictionary
    UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    
    // Dismiss controller
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    
    // Upload image
    NSData *imageData = UIImageJPEGRepresentation(image, 0.05f);
    currentImageData = imageData;
    //UI AlertViewTesting
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Caption" message:@"Add a photo caption..." delegate:self cancelButtonTitle:@"No" otherButtonTitles: nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert addButtonWithTitle:@"Add"];
    [alert show];
    

}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD hides
    [HUD removeFromSuperview];
	HUD = nil;
}

@end
