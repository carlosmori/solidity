// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Crud {
    address public owner;
    uint256 public activePostCounter;
    uint256 public inactivePostCounter;
    uint256 private postCounter;

    mapping(uint256 => address) public delPostOf;
    mapping(uint256 => address) public authorOf;
    mapping(address => uint256) public postsOf;

    enum Deactivated {
        NO,
        YES
    }

    struct PostStruct {
        uint256 postId;
        string title;
        string description;
        address author;
        Deactivated deleted;
        uint256 created;
        uint256 updated;
    }

    PostStruct[] activePosts;
    PostStruct[] inactivePosts;

    event Action(
        uint256 postId,
        string actionType,
        Deactivated deleted,
        address indexed executor,
        uint256 created
    );

    modifier ownerOnly() {
        require(msg.sender == owner, "Owner reserved only");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createPost(string memory title, string memory description)
        external
        returns (bool)
    {
        // Checks for empty string
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");

        PostStruct memory post = PostStruct(
            postCounter,
            title,
            description,
            msg.sender,
            Deactivated.NO,
            block.timestamp,
            block.timestamp
        );
        // Performs computations
        postCounter++;
        authorOf[postCounter] = msg.sender;
        postsOf[msg.sender]++;
        activePostCounter++;

        // Adds post to array
        activePosts.push(post);

        // Emits a created event
        emit Action(
            postCounter,
            "POST CREATED",
            Deactivated.NO,
            msg.sender,
            block.timestamp
        );

        // Returns success
        return true;
    }

    function updatePost(
        uint256 postId,
        string memory title,
        string memory description
    ) external returns (bool) {
        // Checks for empty string
        require(authorOf[postId] == msg.sender, "Unauthorized entity");
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");

        // Changes post record
        for (uint256 i = 0; i < activePosts.length; i++) {
            if (activePosts[i].postId == postId) {
                activePosts[i].title = title;
                activePosts[i].description = description;
                activePosts[i].updated = block.timestamp;
            }
        }

        // Emits a updated event
        emit Action(
            postId,
            "POST UPDATED",
            Deactivated.NO,
            msg.sender,
            block.timestamp
        );

        // Returns success
        return true;
    }

    // https://ethereum.stackexchange.com/questions/19380/external-vs-public-best-practices
    function showPost(uint256 postId)
        external
        view
        returns (PostStruct memory)
    {
        PostStruct memory post;
        for (uint256 i = 0; i < activePosts.length; i++) {
            if (activePosts[i].postId == postId) {
                post = activePosts[i];
            }
        }
        return post;
    }

    function getPosts() external view returns (PostStruct[] memory) {
        return activePosts;
    }

    function getDeletedPost()
        external
        view
        ownerOnly
        returns (PostStruct[] memory)
    {
        return inactivePosts;
    }

    function deletePost(uint256 postId) external returns (bool) {
        // check if post belong to user
        require(authorOf[postId] == msg.sender, "Unauthorized entity");

        // find and delete post
        for (uint256 i = 0; i < activePosts.length; i++) {
            if (activePosts[i].postId == postId) {
                activePosts[i].deleted = Deactivated.YES;
                activePosts[i].updated = block.timestamp;
                inactivePosts.push(activePosts[i]);
                delPostOf[postId] = authorOf[postId];
                delete activePosts[i];
                delete authorOf[postId];
            }
        }

        // Recallibrate counters
        postsOf[msg.sender]--;
        inactivePostCounter++;
        activePostCounter--;

        // Emits event
        emit Action(
            postId,
            "POST DELETED",
            Deactivated.YES,
            msg.sender,
            block.timestamp
        );

        // Returns success
        return true;
    }

    function restorDeletedPost(uint256 postId, address author)
        external
        ownerOnly
        returns (bool)
    {
        // checks if post exists in users recycle bin
        require(delPostOf[postId] == author, "Unmatched Author");

        // Finds and restore the post to the author
        for (uint256 i = 0; i < inactivePosts.length; i++) {
            if (inactivePosts[i].postId == postId) {
                inactivePosts[i].deleted = Deactivated.NO;
                inactivePosts[i].updated = block.timestamp;
                activePosts.push(inactivePosts[i]);
                delete inactivePosts[i];
                authorOf[postId] = delPostOf[postId];
                delete delPostOf[postId];
            }
        }

        // Recallibrates counter to reflect restored post
        postsOf[author]++;
        inactivePostCounter--;
        activePostCounter++;

        // Emits a restoration event
        emit Action(
            postId,
            "POST RESTORED",
            Deactivated.NO,
            msg.sender,
            block.timestamp
        );

        // resturns success
        return true;
    }
}
