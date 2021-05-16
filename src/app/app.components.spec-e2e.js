import { AngularSelector, waitForAngular } from 'testcafe-angular-selectors';
import { Selector } from 'testcafe';

fixture `Basic Tests`
    .page `http://localhost:4200`
    .beforeEach(async () => {
        await waitForAngular();
    });

// this is needed for the load from DB test
let userId;

test('Initial Load Headlines', async t => {
    await t.expect(AngularSelector().find('[data-test="login-h2"]').innerText).eql("User Login")
});

test('Login', async t => {
    const givenUserId = await Selector('[name="userid"]').value

    await t
        .click(AngularSelector().find('app-user-login').find("button"))
        .expect(AngularSelector().find('app-user-login').find('div').innerText).contains('User: ' + givenUserId)
        .expect(AngularSelector().find('[data-test="newbook-h2"]').innerText).eql("New Book")
        .expect(AngularSelector().find('[data-test="books-h2"]').innerText).eql("Books")
        .expect(AngularSelector().find('[data-test="mycollection-h2"').innerText).eql("My Collection")
});

test('Create new book', async t => {
    userId = await Selector('[name="userid"]').value

    await t
        .click(AngularSelector().find('app-user-login').find("button"))
        .expect(AngularSelector().find('app-book-list').find('.book-item').count).eql(0)
        .typeText('[data-test="newBook-titel"]', "new test title")
        .typeText('[data-test="newBook-authors"]', "new authors one")
        .click(AngularSelector().find("app-book-add").find("button"))
        .expect(AngularSelector().find('app-book-list').find('.book-item').count).eql(1)
        .expect(AngularSelector().find('app-book-collection').find('.book-item').count).eql(0)
});

test('Add book to collection', async t => {
    await t
        .click(AngularSelector().find('app-user-login').find("button"))
        .typeText('[data-test="newBook-titel"]', "new test title")
        .typeText('[data-test="newBook-authors"]', "new authors one")
        .click(AngularSelector().find("app-book-add").find("button"))
        .expect(AngularSelector().find('app-book-list').find('.book-item').count).eql(1)
        .expect(AngularSelector().find('app-book-collection').find('.book-item').count).eql(0)
        .click(AngularSelector().find('[data-test="add-button"]'))
        .expect(AngularSelector().find('app-book-list').find('.book-item').count).eql(1)
        .expect(AngularSelector().find('app-book-collection').find('.book-item').count).eql(1)
});

test('Delete book from collection', async t => {
    await t
        .click(AngularSelector().find('app-user-login').find("button"))
        .typeText('[data-test="newBook-titel"]', "new test title")
        .typeText('[data-test="newBook-authors"]', "new authors one")
        .click(AngularSelector().find("app-book-add").find("button"))
        .click(AngularSelector().find('[data-test="add-button"]'))
        .click(AngularSelector().find('[data-test="remove-button"]'))
        .expect(AngularSelector().find('app-book-list').find('.book-item').count).eql(1)
        .expect(AngularSelector().find('app-book-collection').find('.book-item').count).eql(0)
});

test('Load from DB', async t => {
    await t
        .click('[name="userid"]')
        .pressKey('ctrl+a delete')
        .typeText('[name="userid"]', userId)
        .click(AngularSelector().find('app-user-login').find("button"))
        .expect(AngularSelector().find('app-book-list').find('.book-item').count).eql(1)
});

test('Mass add after load', async t => {
    await t
        .click('[name="userid"]')
        .pressKey('ctrl+a delete')
        .typeText('[name="userid"]', userId)
        .click(AngularSelector().find('app-user-login').find("button"))

    for (let i = 0 ; i < 5 ; i++) {
        await t
            .typeText('[data-test="newBook-titel"]', "new test title" + Math.random())
            .typeText('[data-test="newBook-authors"]', "new authors one" + Math.random())
            .click(AngularSelector().find("app-book-add").find("button"))
    }

    await t
        .expect(AngularSelector().find('app-book-list').find('.book-item').count).eql(6)
        .expect(AngularSelector().find('app-book-collection').find('.book-item').count).eql(0)
});
